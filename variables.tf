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

variable "existing_tip_group_name" {
  # Mandatory parameter.
  #
  # Template will use it to start the GSLB Virtual Server on.
  #
  description = "Name of an existing TIP Group to use."
}

### Secondary vTM cluster ###
#
# This is optional. If specified, this will configure the secondary vTM
#
# The main variable is the "vtm_rest_ip_2" - if specified, this will trigger
# creation of the config objects for the second vTM cluster.
#
# If any of the below is set to "", template will reuse value from the primary.
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

variable "existing_tip_group_name_2" {
  # Mandatory parameter.
  #
  # Template will use it to start the GSLB Virtual Server on.
  #
  description = "Name of an existing TIP Group on secondary vTM to use."

  default = ""
}

### End of Secondary vTM cluster variables ###

variable "monitor_http_path" {
  description = "HTTP path for the GSLB Location Monitor"

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

variable "ns1_ip" {
  # This would be an IP that belongs to the 'existing_tip_group_name'
  description = "Public IP on your vTM to use for GSLB glue record 'ns1'."
}

variable "ns2_ip" {
  # This would be another IP that belongs to the 'existing_tip_group_name', or
  # an IP that belongs to 'existing_tip_group_name_2' if you use secondary vTM
  description = "Public IP on your vTM to use for GSLB glue record 'ns2'."
}
