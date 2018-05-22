variable "loc1_ips" {
  # List, e.g.: ["10.10.10.10", "20.20.20.20"]
  #
  description = "Public IP(s) of the Location 1"

  default = []
}

variable "loc1_mon_port" {
  description = "IP port to use for monitoring of this location's IPs"
  default     = "443"
}

variable "loc1_lat" {
  # Float value, e.g., "44.08"
  description = "Latitude of the Location 1"
}

variable "loc1_lon" {
  # Float value, e.g., "-120.74"
  description = "Longitude of the Location 1"
}
