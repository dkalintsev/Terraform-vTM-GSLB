resource "vtm_location" "location_2" {
  name       = "${var.env_id}-Location-2"
  identifier = "2"
  latitude   = "${var.loc2_lat}"
  longitude  = "${var.loc2_lon}"
  type       = "glb"
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

### Secondary vTM cluster resources

resource "vtm_location" "location_2_2" {
  provider = "vtm.secondary"
  count    = "${local.secondary_count}"

  name       = "${var.env_id}-Location-2"
  identifier = "2"
  latitude   = "${var.loc2_lat}"
  longitude  = "${var.loc2_lon}"
  type       = "glb"
}

resource "vtm_monitor" "monitor_loc_2_2" {
  provider = "vtm.secondary"
  count    = "${local.secondary_count == 0 ?
    0 : length(var.loc2_ips)}"

  name      = "${var.env_id}-Mon-Loc-2-${format("%02d", count.index + 1)}"
  machine   = "${element(var.loc2_ips, count.index)}:443"
  scope     = "poolwide"
  type      = "http"
  use_ssl   = "true"
  http_path = "${var.monitor_http_path}"
}
