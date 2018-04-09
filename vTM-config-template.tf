provider "vtm" {
  base_url        = "https://${var.vtm_rest_ip}:${var.vtm_rest_port}/api"
  password        = "${var.vtm_password}"
  verify_ssl_cert = false
}

data "vtm_traffic_ip_group" "tip_group" {
  name = "${var.existing_tip_group_name}"
}

locals {
  # Gather IPs of all remote endpoints and dedupe them (just in case)
  ips = "${distinct(concat(var.loc1_ips, var.loc2_ips))}"

  # Convert them into "<host> IN A <IP>\n" format
  dns_lines = "${join("", formatlist("${var.global_host_name} IN A %s\n", local.ips))}"

  # Concatenate zone template with the resulting list of A-records
  zone = "${data.template_file.glb_zone.rendered}\n${local.dns_lines}"

  # Make a List of Traffic IPs for delegation
  vtm_tip1 = "${data.vtm_traffic_ip_group.tip_group.ipaddresses[0]}"
  vtm_tip2 = "${data.vtm_traffic_ip_group.tip_group.ipaddresses[1]}"

  #vtm_tip1 = "${signum(length(var.existing_tip_group_name)) == "1" ? var.vtm_tips[0] : element(data.vtm_traffic_ip_group.tip_group.*.ipaddresses[0], 0)}"
  #vtm_tip2 = "${length(var.existing_tip_group_name) == "1" ? var.vtm_tips[1] : element(data.vtm_traffic_ip_group.tip_group.*.ipaddresses[0], 1)}"
  # DNS Records for the origin zone
  glue_record1 = "${format("ns1.${var.dns_subdomain}.${var.dns_domain}. IN A %s", local.vtm_tip1)}"

  glue_record2 = "${format("ns2.${var.dns_subdomain}.${var.dns_domain}. IN A %s", local.vtm_tip2)}"
  ns_record1   = "${format("${var.dns_subdomain} IN NS ns1.${var.dns_subdomain}.${var.dns_domain}.")}"
  ns_record2   = "${format("${var.dns_subdomain} IN NS ns2.${var.dns_subdomain}.${var.dns_domain}.")}"
}

data "template_file" "glb_zone" {
  template = "${file("${path.module}/files/GLB-zone.txt")}"

  vars {
    dns_domain    = "${var.dns_domain}"
    dns_subdomain = "${var.dns_subdomain}"
    vtm_tip1      = "${local.vtm_tip1}"
    vtm_tip2      = "${local.vtm_tip2}"
  }
}

resource "vtm_zone_file" "glb_zone_file" {
  name    = "${var.env_id}-GLB-zone.txt"
  content = "${local.zone}"
}

resource "vtm_zone" "glb_zone" {
  name     = "${var.env_id}-GLB-Zone-1"
  origin   = "${var.dns_subdomain}.${var.dns_domain}"
  zonefile = "${vtm_zone_file.glb_zone_file.name}"
}

resource "vtm_location" "location_1" {
  name       = "${var.env_id}-Location-1"
  identifier = "1"
  latitude   = "${var.loc1_lat}"
  longitude  = "${var.loc1_lon}"
  type       = "glb"
}

resource "vtm_location" "location_2" {
  name       = "${var.env_id}-Location-2"
  identifier = "2"
  latitude   = "${var.loc2_lat}"
  longitude  = "${var.loc2_lon}"
  type       = "glb"
}

resource "vtm_monitor" "monitor_loc_1" {
  count     = "${length(var.loc1_ips)}"
  name      = "${var.env_id}-Mon-Loc-1-${format("%02d", count.index + 1)}"
  machine   = "${element(var.loc1_ips, count.index)}:443"
  scope     = "poolwide"
  type      = "http"
  use_ssl   = "true"
  http_path = "${var.monitor_http_path}"
}

resource "vtm_monitor" "monitor_loc_2" {
  count     = "${length(var.loc2_ips)}"
  name      = "${var.env_id}-Mon-Loc-2-${format("%02d", count.index + 1)}"
  machine   = "${element(var.loc2_ips, count.index)}:443"
  scope     = "poolwide"
  type      = "http"
  use_ssl   = "true"
  http_path = "${var.monitor_http_path}"
}

resource "vtm_glb_service" "glb_service" {
  name                   = "${var.env_id}-GLB-Service-1"
  chained_location_order = ["${vtm_location.location_1.name}", "${vtm_location.location_2.name}"]
  domains                = ["${var.global_host_name}.${var.dns_subdomain}.${var.dns_domain}"]
  enabled                = "true"

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

/*resource "vtm_traffic_ip_group" "tip_group" {
  name        = "${var.env_id}-TIP-Group-1"
  ipaddresses = ["${local.vtm_tip1}", "${local.vtm_tip2}"]
  machines    = "${var.vtm_machines}"
  mode        = "ec2vpcelastic"                            # singlehosted
}*/

resource "vtm_virtual_server" "glb_demo" {
  name          = "${var.env_id}-GLB-VS-1"
  enabled       = "true"
  glb_services  = ["${vtm_glb_service.glb_service.name}"]
  listen_on_any = "false"

  #listen_on_traffic_ips = ["${vtm_traffic_ip_group.tip_group.name}"]
  listen_on_traffic_ips = ["${var.existing_tip_group_name}"]
  pool                  = "builtin_dns"
  port                  = "53"
  protocol              = "dns"
  dns_zones             = ["${vtm_zone.glb_zone.name}"]
}

output "origin_zone_records" {
  # To add to the ${var.dns_domain} zone
  value = ["${local.ns_record1}", "${local.ns_record2}", "${local.glue_record1}", "${local.glue_record2}"]
}

output "test" {
  value = "${length(var.existing_tip_group_name)}"
}
