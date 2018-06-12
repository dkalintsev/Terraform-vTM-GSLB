variable "env_id" {
  # Passed from the calling template
}

variable "sec_count" {
  description = "Count value to determine if we need second vTM cluster config"
}

variable "loc_ips" {
  # List, e.g.: ["10.10.10.10", "20.20.20.20"]
  #
  description = "Public IP(s) of the Location"

  default = []
}

variable "loc_mon_port" {
  description = "IP port to use for monitoring of this location's IPs"
}

variable "loc_use_ssl" {
  description = "Whether to use SSL in Location Monitor"
}

variable "loc_lat" {
  # Float value, e.g., "44.08"
  description = "Latitude of the Location"
}

variable "loc_lon" {
  # Float value, e.g., "-120.74"
  description = "Longitude of the Location"
}

variable "loc_num" {
  # Sequential number for the location, used for ID and resource names
  description = "Number of this location"
}

variable "monitor_http_path" {
  description = "HTTP path to use for the monitor"
}
