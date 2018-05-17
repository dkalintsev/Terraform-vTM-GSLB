resource "vtm_location" "location_1" {
  name       = "${var.env_id}-Location-1"
  identifier = "1"
  latitude   = "${var.loc1_lat}"
  longitude  = "${var.loc1_lon}"
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

### Secondary vTM cluster resources

resource "vtm_location" "location_1_2" {
  provider = "vtm.secondary"
  count    = "${local.secondary_count}"

  name       = "${var.env_id}-Location-1"
  identifier = "1"
  latitude   = "${var.loc1_lat}"
  longitude  = "${var.loc1_lon}"
  type       = "glb"
}

resource "vtm_monitor" "monitor_loc_1_2" {
  provider = "vtm.secondary"
  count    = "${local.secondary_count == 0 ?
    0 : length(var.loc1_ips)}"

  name      = "${var.env_id}-Mon-Loc-1-${format("%02d", count.index + 1)}"
  machine   = "${element(var.loc1_ips, count.index)}:443"
  scope     = "poolwide"
  type      = "http"
  use_ssl   = "true"
  http_path = "${var.monitor_http_path}"
}
