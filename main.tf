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
    zone_serial   = "${var.zone_serial}"
  }
}

resource "null_resource" "ns" {
  # This creates a number of strings we need for NS records, based on the
  # list of traffic IPs collected in local.all_tips
  count = "${length(local.all_tips)}"

  triggers {
    ns_host = "ns${format("%d", count.index + 1)}"
  }
}

locals {
  # Create NS records for the zone from all Traffic IPs we have

  # Gather all Traffic IPs that were given to us
  all_tips = "${flatten(list(var.traffic_ips, var.traffic_ips_2))}"

  # Create a list of "  IN NS nsN.blah.com."
  in_ns_list = "${formatlist(
    "    IN NS %s.${var.dns_subdomain}.${var.dns_domain}.",
    null_resource.ns.*.triggers.ns_host)}"

  # Pull the list into a string joined by new lines
  in_ns_string = "${join("\n", local.in_ns_list)}"

  # Create a list of "nsN  IN A x.x.x.x"
  ns_in_a_list = "${formatlist(
    "%s  IN A %s",
    null_resource.ns.*.triggers.ns_host,
    local.all_tips)}"

  # Pull the list into a string joined by new lines
  ns_in_a_string = "${join("\n", local.ns_in_a_list)}"
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
  zone = "${data.template_file.glb_zone.rendered}\n${local.in_ns_string}\n${local.ns_in_a_string}\n${local.dns_lines}"

  # DNS Records for the origin zone. Generated as output for convenience.
  # These are to be added to the zone of the dns_domain manually
  #
  glue_records = "${formatlist(
    "%s.${var.dns_subdomain}.${var.dns_domain}.  IN A %s",
    null_resource.ns.*.triggers.ns_host,
    local.all_tips)}"

  ns_records = "${formatlist(
    "${var.dns_subdomain}    IN NS %s.${var.dns_subdomain}.${var.dns_domain}.",
    null_resource.ns.*.triggers.ns_host)}"

  cname_record = "${var.global_host_name} IN CNAME ${var.global_host_name}.${var.dns_subdomain}.${var.dns_domain}."
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

# This returns a list populated with "name" values of all traffic managers
# in the target cluster. We need this to create the Traffic IP Group.
#
data "vtm_traffic_manager_list" "cluster_machines" {
  # No parameters needed
}

# Traffic IP Group for our Virtual Server.
#
resource "vtm_traffic_ip_group" "tip_group" {
  name        = "${var.env_id}-GSLB-TIP-Group"
  mode        = "${var.tip_type}"
  ipaddresses = "${var.traffic_ips}"
  machines    = ["${data.vtm_traffic_manager_list.cluster_machines.object_list}"]
}

resource "vtm_virtual_server" "glb_demo" {
  name                  = "${var.env_id}-GLB-VS-1"
  enabled               = "true"
  glb_services          = ["${vtm_glb_service.glb_service.name}"]
  listen_on_any         = "false"
  listen_on_traffic_ips = ["${vtm_traffic_ip_group.tip_group.name}"]
  pool                  = "builtin_dns"
  port                  = "53"
  protocol              = "dns"
  dns_zones             = ["${vtm_dns_server_zone.glb_zone.name}"]
}

output "origin_zone_records" {
  # To add to the ${var.dns_domain} zone manually
  value = [
    "${local.ns_records}",
    "${local.glue_records}",
    "${local.cname_record}",
  ]
}
