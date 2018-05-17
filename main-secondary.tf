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

  # Was alternative TIP Group name specified for secondary?
  existing_tip_group_name_2 = "${var.existing_tip_group_name_2 != "" ?
    var.existing_tip_group_name_2 : var.existing_tip_group_name}"
}

provider "vtm" {
  alias = "secondary"

  # base_url will be invalid if rest_ip_2 isn't specified; but that's ok
  # since we won't be creating any resources on it then.
  base_url = "https://${local.vtm_rest_ip_2}:${local.vtm_rest_port_2}/api"

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
  chained_location_order = ["${vtm_location.location_1_2.name}", "${vtm_location.location_2_2.name}"]

  domains = ["${var.global_host_name}.${var.dns_subdomain}.${var.dns_domain}"]
  enabled = "true"

  # If adding more locations, add corresponding section below:

  location_settings {
    location = "${vtm_location.location_1_2.name}"
    ips      = "${var.loc1_ips}"
    monitors = ["${vtm_monitor.monitor_loc_1_2.*.name}"]
  }
  location_settings {
    location = "${vtm_location.location_2_2.name}"
    ips      = "${var.loc2_ips}"
    monitors = ["${vtm_monitor.monitor_loc_2_2.*.name}"]
  }
}

resource "vtm_virtual_server" "glb_demo_2" {
  provider = "vtm.secondary"
  count    = "${local.secondary_count}"

  name          = "${var.env_id}-GLB-VS-1"
  enabled       = "true"
  glb_services  = ["${vtm_glb_service.glb_service_2.name}"]
  listen_on_any = "false"

  listen_on_traffic_ips = ["${local.existing_tip_group_name_2}"]
  pool                  = "builtin_dns"
  port                  = "53"
  protocol              = "dns"
  dns_zones             = ["${vtm_dns_server_zone.glb_zone_2.name}"]
}