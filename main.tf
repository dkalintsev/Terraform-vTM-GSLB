provider "vtm" {
  base_url        = "https://${var.vtm_rest_ip}:${var.vtm_rest_port}/api"
  username        = "${var.vtm_username}"
  password        = "${var.vtm_password}"
  verify_ssl_cert = false
  version         = "~> 4.0.0"
}

locals {
  # Gather IPs of all remote endpoints and dedupe them (just in case)
  ips = "${distinct(concat(var.loc1_ips, var.loc2_ips))}"

  # Convert them into "<host> IN A <IP>\n" format
  dns_lines = "${join("", formatlist("${var.global_host_name} IN A %s\n", local.ips))}"

  # Concatenate zone template with the resulting list of A-records
  zone = "${data.template_file.glb_zone.rendered}\n${local.dns_lines}"

  # DNS Records for the origin zone
  glue_record1 = "${format("ns1.${var.dns_subdomain}.${var.dns_domain}. IN A %s", var.ns1_ip)}"
  glue_record2 = "${format("ns2.${var.dns_subdomain}.${var.dns_domain}. IN A %s", var.ns2_ip)}"
  ns_record1   = "${format("${var.dns_subdomain} IN NS ns1.${var.dns_subdomain}.${var.dns_domain}.")}"
  ns_record2   = "${format("${var.dns_subdomain} IN NS ns2.${var.dns_subdomain}.${var.dns_domain}.")}"
}

data "template_file" "glb_zone" {
  template = "${file("${path.module}/files/GLB-zone.txt")}"

  vars {
    dns_domain    = "${var.dns_domain}"
    dns_subdomain = "${var.dns_subdomain}"
    ns1_ip        = "${var.ns1_ip}"
    ns2_ip        = "${var.ns2_ip}"
  }
}

resource "vtm_dns_server_zone_file" "glb_zone_file" {
  name    = "${var.env_id}-GLB-zone.txt"
  content = "${local.zone}"
}

resource "vtm_dns_server_zone" "glb_zone" {
  name     = "${var.env_id}-GLB-Zone-1"
  origin   = "${var.dns_subdomain}.${var.dns_domain}"
  zonefile = "${vtm_dns_server_zone_file.glb_zone_file.name}"
}

resource "vtm_glb_service" "glb_service" {
  name = "${var.env_id}-GLB-Service-1"

  # If adding more locations, update this:
  chained_location_order = ["${vtm_location.location_1.name}", "${vtm_location.location_2.name}"]

  domains = ["${var.global_host_name}.${var.dns_subdomain}.${var.dns_domain}"]
  enabled = "true"

  # If adding more locations, add corresponding section below:

  location_settings {
    location = "${vtm_location.location_1.name}"
    ips      = "${var.loc1_ips}"
    monitors = ["${vtm_monitor.monitor_loc_1.*.name}"]
  }
  location_settings {
    location = "${vtm_location.location_2.name}"
    ips      = "${var.loc2_ips}"
    monitors = ["${vtm_monitor.monitor_loc_2.*.name}"]
  }
}

resource "vtm_virtual_server" "glb_demo" {
  name          = "${var.env_id}-GLB-VS-1"
  enabled       = "true"
  glb_services  = ["${vtm_glb_service.glb_service.name}"]
  listen_on_any = "false"

  listen_on_traffic_ips = ["${var.existing_tip_group_name}"]
  pool                  = "builtin_dns"
  port                  = "53"
  protocol              = "dns"
  dns_zones             = ["${vtm_dns_server_zone.glb_zone.name}"]
}

output "origin_zone_records" {
  # To add to the ${var.dns_domain} zone
  value = ["${local.ns_record1}", "${local.ns_record2}", "${local.glue_record1}", "${local.glue_record2}"]
}
