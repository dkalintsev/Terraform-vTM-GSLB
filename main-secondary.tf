# Copyright (c) 2018 Pulse Secure LLC.
#
locals {
  # Conditions to handle configuration for the secondary vTM cluster
  secondary_count = "${var.vtm_rest_ip_2 != "" ? 1 : 0}"

  # Was alternative REST IP specified for secondary?
  #
  # ### WARNING: A DIRTY HACK. ###
  # Terraform still wants to connect to a secondary provider even if there
  # are no resources that need to be created on it. So we'll give it the IP
  # of the primary vTM so it can connect and be happy.
  #
  vtm_rest_ip_2 = "${var.vtm_rest_ip_2 != "" ?
    var.vtm_rest_ip_2 : var.vtm_rest_ip}"

  # Was alternative REST port specified for secondary?
  vtm_rest_port_2 = "${var.vtm_rest_port_2 != "" ?
    var.vtm_rest_port_2 : var.vtm_rest_port}"

  # Was alternative username specified for secondary?
  vtm_username_2 = "${var.vtm_username_2 != "" ?
    var.vtm_username_2 : var.vtm_username}"

  # Was alternative password specified for secondary?
  vtm_password_2 = "${var.vtm_password_2 != "" ?
    var.vtm_password_2 : var.vtm_password}"
}

provider "vtm" {
  alias           = "secondary"
  base_url        = "https://${local.vtm_rest_ip_2}:${local.vtm_rest_port_2}/api"
  username        = "${local.vtm_username_2}"
  password        = "${local.vtm_password_2}"
  verify_ssl_cert = false
  version         = "~> 4.0.0"
}

resource "vtm_dns_server_zone_file" "glb_zone_file_2" {
  provider = "vtm.secondary"
  count    = "${local.secondary_count}"

  name    = "${var.env_id}-GLB-zone.txt"
  content = "${local.zone}"
}

resource "vtm_dns_server_zone" "glb_zone_2" {
  provider = "vtm.secondary"
  count    = "${local.secondary_count}"

  name     = "${var.env_id}-GLB-Zone-1"
  origin   = "${var.dns_subdomain}.${var.dns_domain}"
  zonefile = "${vtm_dns_server_zone_file.glb_zone_file_2.name}"
}

resource "vtm_glb_service" "glb_service_2" {
  provider = "vtm.secondary"
  count    = "${local.secondary_count}"

  name = "${var.env_id}-GLB-Service-1"

  # If adding more locations, update this:
  chained_location_order = [
    "${module.loc1.loc_name}",
    "${module.loc2.loc_name}",
  ]

  domains = ["${var.global_host_name}.${var.dns_subdomain}.${var.dns_domain}"]
  enabled = "true"

  # If adding more locations, add corresponding section below:
  # Location 1
  location_settings {
    location = "${module.loc1.loc_name}"
    ips      = "${var.loc1_ips}"
    monitors = ["${module.loc1.mon_loc_name}"]
  }

  # Location 2
  location_settings {
    location = "${module.loc2.loc_name}"
    ips      = "${var.loc2_ips}"
    monitors = ["${module.loc2.mon_loc_name}"]
  }
}

# This returns a list populated with "name" values of all traffic managers
# in the target cluster. We need this to create the Traffic IP Group.
#
data "vtm_traffic_manager_list" "cluster_machines_2" {
  provider = "vtm.secondary"
  count    = "${local.secondary_count}"
}

# Traffic IP Group for our Virtual Server.
#
resource "vtm_traffic_ip_group" "tip_group_2" {
  provider = "vtm.secondary"
  count    = "${local.secondary_count}"

  name        = "${var.env_id}-GSLB-TIP-Group"
  mode        = "${var.tip_type_2}"
  ipaddresses = "${var.traffic_ips_2}"
  machines    = ["${data.vtm_traffic_manager_list.cluster_machines_2.object_list}"]
}

resource "vtm_virtual_server" "glb_demo_2" {
  provider = "vtm.secondary"
  count    = "${local.secondary_count}"

  name          = "${var.env_id}-GLB-VS-1"
  enabled       = "true"
  glb_services  = ["${vtm_glb_service.glb_service_2.name}"]
  listen_on_any = "false"

  listen_on_traffic_ips = ["${vtm_traffic_ip_group.tip_group_2.name}"]
  pool                  = "builtin_dns"
  port                  = "53"
  protocol              = "dns"
  dns_zones             = ["${vtm_dns_server_zone.glb_zone_2.name}"]
}
