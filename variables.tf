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

variable "vtm_username" {
  description = "Login to use to connect to vTM"
  default     = "admin"
}

variable "vtm_password" {
  description = "Password of the 'admin' account on the vTM"
}

variable "traffic_ips" {
  # Mandatory parameter.
  #
  # Template will use it to create TIP Group for the GSLB Virtual Server.
  #
  description = "List of IP addresses for GSLB TIP Group"

  default = []
}

variable "tip_type" {
  description = "Type of the Traffic IP Group, e.g., 'singlehosted' or 'ec2vpcelastic'"
  default     = "singlehosted"
}

### Secondary vTM cluster ###
#
# This is optional. If specified, this will configure the secondary vTM
#
# The main variable is the "vtm_rest_ip_2" - if specified, this will trigger
# creation of the config objects for the second vTM cluster.
#
# If any of the below 'vtm_*' variables is set to "", template will reuse
# correponding value from the primary.
#
variable "vtm_rest_ip_2" {
  description = "IP or FQDN of the vTM REST API endpoint, e.g. '192.168.0.1'"
  default     = ""
}

variable "vtm_rest_port_2" {
  description = "TCP port of the vTM REST API endpoint"
  default     = "9070"
}

variable "vtm_username_2" {
  description = "Login to use to connect to vTM"
  default     = "admin"
}

variable "vtm_password_2" {
  description = "Password of the 'admin' account on the vTM"
  default     = ""
}

variable "traffic_ips_2" {
  # Mandatory parameter.
  #
  # Template will use it to create TIP Group for the GSLB Virtual Server.
  #
  description = "List of IP addresses for GSLB TIP Group"

  default = []
}

variable "tip_type_2" {
  description = "Type of the Traffic IP Group, e.g., 'singlehosted' or 'ec2vpcelastic'"
  default     = "singlehosted"
}

### End of Secondary vTM cluster variables ###

#############
# DNS details
#############

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

variable "zone_serial" {
  description = "Serial for the GSLB DNS Zone's SOA record"
  default     = "2018050101"
}

#############################
# Location monitor parameters
#############################

variable "monitor_http_path" {
  description = "HTTP path for the GSLB Location Monitor"

  # Default for PCS
  default = "/dana-na/auth/url_default/welcome.cgi"
}

variable "loc_mon_port" {
  description = "TCP/UDP Port to use for monitoring location endpoints"
  default     = "443"
}

variable "loc_use_ssl" {
  description = "Flag to whether to use SSL for location endpoint monitoring"
  default     = "true"
}
