provider "vtm" {
  # Explicit provider pass-through
}

provider "vtm" {
  # Explicit pass-throgh of the secondary
  alias = "secondary"
}

resource "vtm_location" "location" {
  name       = "${var.env_id}-Location-${var.loc_num}"
  identifier = "${var.loc_num}"
  latitude   = "${var.loc_lat}"
  longitude  = "${var.loc_lon}"
  type       = "glb"
}

resource "vtm_monitor" "monitor_loc" {
  count     = "${length(var.loc_ips)}"
  name      = "${var.env_id}-Mon-Loc-${var.loc_num}-${format("%02d", count.index + 1)}"
  machine   = "${element(var.loc_ips, count.index)}:${var.loc_mon_port}"
  scope     = "poolwide"
  type      = "http"
  use_ssl   = "true"
  http_path = "${var.monitor_http_path}"
}

### Secondary vTM cluster resources

resource "vtm_location" "location_2" {
  provider   = "vtm.secondary"
  count      = "${var.sec_count}"
  name       = "${var.env_id}-Location-${var.loc_num}"
  identifier = "${var.loc_num}"
  latitude   = "${var.loc_lat}"
  longitude  = "${var.loc_lon}"
  type       = "glb"
}

resource "vtm_monitor" "monitor_loc_2" {
  provider = "vtm.secondary"
  count    = "${var.sec_count == 0 ?
    0 : length(var.loc_ips)}"

  name      = "${var.env_id}-Mon-Loc-${var.loc_num}-${format("%02d", count.index + 1)}"
  machine   = "${element(var.loc_ips, count.index)}:${var.loc_mon_port}"
  scope     = "poolwide"
  type      = "http"
  use_ssl   = "true"
  http_path = "${var.monitor_http_path}"
}

output "loc_name" {
  value = "${vtm_location.location.name}"
}

output "loc_name_2" {
  value = "${vtm_location.location_2.*.name}"
}

output "mon_loc_name" {
  value = "${vtm_monitor.monitor_loc.*.name}"
}

output "mon_loc_name_2" {
  value = "${vtm_monitor.monitor_loc_2.*.name}"
}
