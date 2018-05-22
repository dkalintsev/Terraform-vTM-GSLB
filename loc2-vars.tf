variable "loc2_ips" {
  description = "Public IP(s) of the Location 2"
  default     = []
}

variable "loc2_mon_port" {
  description = "IP port to use for monitoring of this location's IPs"
  default     = "443"
}

variable "loc2_lat" {
  description = "Latitude of the Location 2"
}

variable "loc2_lon" {
  description = "Longitude of the Location 2"
}
