variable "env_id" {
  # Value of this variable is prepended to names of all vTM resources this
  # template creates. Use a reasonably short one, for example, 'x4af'
  #
  description = "Unique ID of this template's instance, used for vTM resource naming."
}

variable "vtm_rest_ip" {
  description = "IP or FQDN of the vTM REST API endpoint, e.g. '192.168.0.1'"
}

variable "vtm_rest_port" {
  description = "TCP port of the vTM REST API endpoint"
  default     = "9070"
}

variable "vtm_password" {
  description = "Password of the 'admin' account on the vTM"
}

variable "existing_tip_group_name" {
  # If this is specified, template will extract Traffic IPs from this TIP Group
  # and use it to start the GSLB Virtual Server on. Value given to vtm_tip
  # variable is ignored.
  #
  # If this is empty, you must provide at least two valid Elastic IPs that will
  # be used to create a new TIP Group for GSLB Virtual Server.
  #
  description = "Name of an existing TIP Group to use."

  default = ""
}

# If the existing_tip_group_name above is empty, template will use Elastic IPs
# specified in this variable to create a new TIP Group.
# At least two IPs must be provided.
#
# List, e.g.: ["1.1.1.1", "2.2.2.2"]
#
variable "vtm_tips" {
  description = "List of vTM Traffic IP addresses; at *least two* are required."
  default     = []
}

variable "loc1_ips" {
  # List, e.g.: ["10.10.10.10", "20.20.20.20"]
  #
  description = "Public IP(s) of the Location 1"

  default = []
}

variable "loc1_lat" {
  # Float value, e.g., "44.08"
  description = "Latitude of the Location 1"
}

variable "loc1_lon" {
  # Float value, e.g., "-120.74"
  description = "Longitude of the Location 1"
}

variable "loc2_ips" {
  description = "Public IP(s) of the Location 2"
  default     = []
}

variable "loc2_lat" {
  description = "Latitude of the Location 2"
}

variable "loc2_lon" {
  description = "Longitude of the Location 2"
}

variable "vtm_machines" {
  description = "List of string names of vTMs in cluster"
  default     = []
}

variable "monitor_http_path" {
  description = "HTTP path for the GLB Location Monitor"

  # Default for PCS
  default = "/dana-na/auth/url_default/welcome.cgi"
}

variable "dns_domain" {
  description = "DNS domain for the GLB Zone file"
}

variable "dns_subdomain" {
  description = "Sub-domain name that will be handled by the vTM GLB, without domain name"
  default     = "gslb"
}

variable "global_host_name" {
  description = "Hostname for the global load balancing endpoint, without domain name"
  default     = "vpn"
}
