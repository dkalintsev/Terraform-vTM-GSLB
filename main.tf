provider "vtm" {
  base_url        = "https://${var.vtm_rest_ip}:${var.vtm_rest_port}/api"
  username        = "${var.vtm_username}"
  password        = "${var.vtm_password}"
  verify_ssl_cert = false
  version         = "~> 4.0.0"
}

data "template_file" "glb_zone" {
  # Populate the zone file template with main parameters, including NS records
  #
  template = "${file("${path.module}/files/GLB-zone.txt")}"

  vars {
    dns_domain    = "${var.dns_domain}"
    dns_subdomain = "${var.dns_subdomain}"
    ns1_ip        = "${var.ns1_ip}"
    ns2_ip        = "${var.ns2_ip}"
  }
}

locals {
  # Create A records to be added to the zone file:

  # First, gather IPs of all remote endpoints and dedupe them (just in case)
  ips = "${distinct(concat(var.loc1_ips, var.loc2_ips))}"

  # Next, convert them into "<host> IN A <IP>\n" format
  dns_lines = "${join("", formatlist("${var.global_host_name} IN A %s\n", local.ips))}"

  # Now, concatenate the zone template with the resulting list of A-records
  # Varible "zone" now has the complete zone file to be used by vTM DNS server
  #
  zone = "${data.template_file.glb_zone.rendered}\n${local.dns_lines}"

  # DNS Records for the origin zone. Generated as output for convenience.
  # These are to be added to the zone of the dns_domain manually
  #
  glue_record1 = "${format("ns1.${var.dns_subdomain}.${var.dns_domain}. IN A %s", var.ns1_ip)}"

  glue_record2 = "${format("ns2.${var.dns_subdomain}.${var.dns_domain}. IN A %s", var.ns2_ip)}"
  ns_record1   = "${format("${var.dns_subdomain} IN NS ns1.${var.dns_subdomain}.${var.dns_domain}.")}"
  ns_record2   = "${format("${var.dns_subdomain} IN NS ns2.${var.dns_subdomain}.${var.dns_domain}.")}"
}

resource "vtm_dns_server_zone_file" "glb_zone_file" {
  name = "${var.env_id}-GLB-zone.txt"

  # Contents of the Zone file have been prepared through local variables above
  content = "${local.zone}"
}

resource "vtm_dns_server_zone" "glb_zone" {
  name     = "${var.env_id}-GLB-Zone-1"
  origin   = "${var.dns_subdomain}.${var.dns_domain}"
  zonefile = "${vtm_dns_server_zone_file.glb_zone_file.name}"
}

# Location 1; creates vTM Location and Monitor(s)
#
module "loc1" {
  source = "mod_location"

  providers = {
    "vtm"           = "vtm"
    "vtm.secondary" = "vtm.secondary"
  }

  env_id            = "${var.env_id}"
  sec_count         = "${local.secondary_count}"
  loc_ips           = "${var.loc1_ips}"
  loc_mon_port      = "443"
  loc_lat           = "${var.loc1_lat}"
  loc_lon           = "${var.loc1_lon}"
  loc_num           = "1"
  monitor_http_path = "${var.monitor_http_path}"
}

# Location 2; creates vTM Location and Monitor(s)
#
module "loc2" {
  source = "mod_location"

  providers = {
    "vtm"           = "vtm"
    "vtm.secondary" = "vtm.secondary"
  }

  env_id            = "${var.env_id}"
  sec_count         = "${local.secondary_count}"
  loc_ips           = "${var.loc2_ips}"
  loc_mon_port      = "443"
  loc_lat           = "${var.loc2_lat}"
  loc_lon           = "${var.loc2_lon}"
  loc_num           = "2"
  monitor_http_path = "${var.monitor_http_path}"
}

resource "vtm_glb_service" "glb_service" {
  name = "${var.env_id}-GLB-Service-1"

  # If adding more locations, update this:
  chained_location_order = [
    "${module.loc1.loc_name}",
    "${module.loc2.loc_name}",
  ]

  domains = ["${var.global_host_name}.${var.dns_subdomain}.${var.dns_domain}"]
  enabled = "true"

  # If adding more locations, also add a corresponding section below:
  # Location 1:
  location_settings {
    location = "${module.loc1.loc_name}"
    ips      = "${var.loc1_ips}"
    monitors = ["${module.loc1.mon_loc_name}"]
  }

  # Location 2:
  location_settings {
    location = "${module.loc2.loc_name}"
    ips      = "${var.loc2_ips}"
    monitors = ["${module.loc2.mon_loc_name}"]
  }
}

resource "vtm_virtual_server" "glb_demo" {
  name                  = "${var.env_id}-GLB-VS-1"
  enabled               = "true"
  glb_services          = ["${vtm_glb_service.glb_service.name}"]
  listen_on_any         = "false"
  listen_on_traffic_ips = ["${var.existing_tip_group_name}"]
  pool                  = "builtin_dns"
  port                  = "53"
  protocol              = "dns"
  dns_zones             = ["${vtm_dns_server_zone.glb_zone.name}"]
}

output "origin_zone_records" {
  # To add to the ${var.dns_domain} zone manually
  value = ["${local.ns_record1}", "${local.ns_record2}", "${local.glue_record1}", "${local.glue_record2}"]
}
