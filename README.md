# Terraform template for vTM GSLB

## Note on use

This template is based on a solution guide for configuring vTM GSLB to provide geo-optimised access to Pulse PCS. Specifically, this is reflected in the vTM Location and Monitors configuration. If you're planning to use this for something else, please review the `mod_location/location.tf` and make sure configuration parameters for `vtm_location` and `vtm_monitor` are appropriate for your situation.

## Disclaimer

This template is meant to serve as a base that provides examples of most/all parts necessary to implement a vTM GSLB solution. Please use it as such to develop your own that matches the requirements of your project.

## What does this template do

This template can create vTM GSLB configuration on one or two vTM clusters (primary or primary + secondary). As is, template is supplied with support for two Locations, but can be reasonably easily expanded to support more.

The template will create an appropriate vTM DNS zone file, GSLB Locations, Monitors, and Service, and associate them with a new `builtin_dns` vTM Virtual Server (VS) listening on port 53. The VS will be associated with the specified Traffic IP Group that must exist before this configuration is applied. This Traffic IP Group can have the same or different name on primary and secondary vTM clusters.

## Prerequisites

### vTM Cluster(s)

One or two vTM clusters must exist and be reachable on their IP + REST API port from the machine where `terraform` commands are executed.

### vTM Version

This template requires [Terraform Provider for vTM](https://github.com/pulse-vadc/terraform-provider-vtm/releases) for REST API v4.0. This Provider version will work with vTM versions 17.2 and up. It is OK to have different vTM versions between primary and secondary clusters.

### Traffic IP Group(s)

This template creates a Virtual Server for DNS that is attached to a TIP Group. Template requires a name of a valid TIP Group passed to it through the `existing_tip_group_name` variable. If there is a secondary vTM cluster, it can have the same or differently named TIP Group. In the later case, its name can be passed through the `existing_tip_group_name_2` variable.

### 2 x Public IP addresses

Template creates a DNS zone with 2 x `NS` entries in it which have to point to the IP addresses where vTM DNS server is listening. The IP addresses for these entries are passed through two variables called `ns1_ip` and `ns2_ip`.

If using a single vTM cluster, please pass two IPs that belong to that vTM cluster's TIP Group (used above).

If using a primary and a secondary vTM clusters, please pass one IP that belongs to the first vTM cluster's TIP Group, and another that belongs to the second one's. For example, if primary vTM's TIP Group had IPs `1.1.1.1` and `2.2.2.2` in it and secondary's TIP Group had `3.3.3.3` and `4.4.4.4`, pass in `ns1_ip = 1.1.1.1` and `ns2_ip = 3.3.3.3`.

### Subdomain delegation

By default, template will create a zone for a subdomain `gslb` under the domain you pass it through the `dns_domain` variable. Once template is deployed, it displays delegation records that can be placed in the main domain's zone. For example:

```
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

origin_zone_records = [
    gslb IN NS ns1.gslb.example.com.,
    gslb IN NS ns2.gslb.example.com.,
    ns1.gslb.example.com. IN A 1.1.1.1,
    ns2.gslb.example.com. IN A 2.2.2.2
]
```

These delegation records must be applied manually to the respective zone.

### GSLB Locations

Template is supplied with support for 2 locations. Each location requires the following parameters:

- List of IPs at this location that vTM GSLB will monitor and return
- Location's Latitude
- Location's Longitude

> Note: this template expects that the servers at Locations are PCS nodes listening on TCP/443, with health check URL being `/dana-na/auth/url_default/welcome.cgi`. This can be changed in `main.tf` modules `loc1` and `loc2`, parameters `loc_mon_port` and `monitor_http_path`.

## Input Parameters

Variables for this template are defined in three different files: `variables.tf`, `loc1-vars.tf`, and `loc2-vars.tf`. This is done to ease the process of adding new locations.

### `variables.tf`

| Parameter | Description
| --- | ---
| `env_id` | A short string that's added in front of names of all vTM resources template instance creates. This is to help identify resources created by the template, and to support multiple instances of the template applied to the same cluster(s).

#### Primary vTM cluster parameters

| Parameter | Description | Default
| --- | --- | ---
| `vtm_rest_ip` | IP address of one of the vTMs in the primary cluster. This is the vTM node that Terraform will connect to and make REST API calls. | N/A
| `vtm_rest_port` | TCP port of the primary vTM's REST API. This is the TCP port Terraform will use to connect to this vTM's REST API endpoint. | `9070`
| `vtm_username` | Username of the admin user on primary vTM cluster. This is the login Terraform will use to authenticate to the REST API endpoint. | `admin`
| `vtm_password` | Password for the above. | N/A
| `existing_tip_group_name` | Name of the Traffic IP Group on the Primary vTM that DNS VS will be attached to. | N/A

#### Secondary vTM cluster parameters

The next group of variables is used only when there's a secondary vTM cluster. **Do not** specify any of these values if you don't have the secondary vTM cluster.

All these values, except `vtm_rest_ip_2`, are optional; template will use the value specified for the corresponding primary vTM's variable.

| Parameter | Description | Default
| --- | --- | ---
| `vtm_rest_ip_2` | IP address of one of the vTMs in the secondary cluster. | N/A
| `vtm_rest_port_2` | TCP port of the secondary vTM's REST API. | `9070`
| `vtm_username_2` | Username of the admin user on secondary vTM cluster. | `admin`
| `vtm_password_2` | Password for the above. | N/A
| `existing_tip_group_name_2` | Name of the Traffic IP Group on the Secondary vTM that DNS VS will be attached to. | N/A

#### GSLB related parameters

| Parameter | Description | Default
| --- | --- | ---
| `monitor_http_path` | HTTP Path that will be used to monitor health of each location IP. | `/dana-na/auth/url_default/welcome.cgi`
| `dns_domain` | Domain for the GSLB sub-domain. Used to customise the zone file, and configure the vTM's GLB Service. | N/A
| `dns_subdomain` | Sub-domain that will be handled by the vTM GSLB DNS Server. Used for the same as above. | `gslb`
| `global_host_name` | Host name for the GSLB endpoint. Again, as above. | `vpn`
| `ns1_ip` | Public IP address belonging to primary vTM's TIP Group used for GSLB VS. Used to customise the GSLB zone file. | N/A
| `ns2_ip` | Public IP address belonging to either primary vTM's TIP Group or to the secondary vTM's TIP Group, if the secondary vTM cluster is used. | N/A

### `loc1-vars.tf`

These are the parameters for the Location 1.

| Parameter | Description | Default
| --- | --- |
| `loc1_ips` | A list of public IP addresses for the Location 1, for example, `["10.10.10.10", "20.20.20.20"]`. This is used to create Location Monitors. One monitor is created for each IP in this list. | `[]` (empty list)
| `loc1_mon_port` | TCP port that Location IPs should be monitored on; used in Monitor's configuration. | `443`
| `loc1_lat` | Latitude of the Location 1, e.g., `44.08`; used for the Location's, well, location. | N/A
| `loc1_lon` | Longitude of the Location 1, e.g., `-120.74` | N/A

### `loc2-vars.tf`

These are the parameters for the Location 2; they are identical to their counterparts from the Location 1 apart from their names that have `2` instead of `1`.

| Parameter | Description | Default
| --- | --- |
| `loc2_ips` | A list of public IP addresses for the Location 2, for example, `["10.10.10.10", "20.20.20.20"]` | `[]` (empty list)
| `loc2_mon_port` | TCP port that Location IPs should be monitored on | `443`
| `loc2_lat` | Latitude of the Location 2, e.g., `19.08` | N/A
| `loc2_lon` | Longitude of the Location 2, e.g., `72.89` | N/A

## Example use

1. Make a copy of the template for each deployment. Your directory should look something like this:

```
.
|____files
| |____GLB-zone.txt
|____loc1-vars.tf
|____loc2-vars.tf
|____main-secondary.tf
|____main.tf
|____mod_location
| |____location.tf
| |____variables.tf
|____README.md
|____terraform.tfvars
|____variables.tf
```

2. Edit the `terraform.tfvars` file, and populate it with the values from your deployment following the variable guide above.

3. Execute `terraform init` to download additional providers, followed by `terraform get` to initialise the Location template module.

4. Run `terraform plan`, which should display the proposed changes - typically to create around ~20 resources per vTM cluster.

5. Run `terraform apply` to apply the configuration.

## Gotchas

You may get a message similar to the below:

```
Error: Error running plan: 1 error(s) occurred:

* provider.vtm: Failed to connect to Virtual Traffic Manager at 'https://52.64.0.43:9070/api': <nil>
```

This rather confusing message means that Terraform has likely failed to authenticate to the cluster. Please check the `vtm_username` and/or `vtm_password` (for the primary) or matching `_2` one for the secondary cluster.

Similar situation may occur if you haven't supplied value for `vtm_rest_ip_2`, but **did** supply value(s) for one or more other `*_2` variables, such as `vtm_password_2`. Please make sure to remove any `*_2` variable values if you're not using secondary cluster.

## Cuff notes

As it stands now, template doesn't increment Serial Number in the DNS zone, if you change any of the values and re-run `terraform apply` on top of already deployed configuration.

I **think** it's not a problem because you don't normally use Secondary DNS servers with GSLB; but please do let me know if this is wrong.

## Walk-through for adding another location

If you need more locations, the process to add more is as follows:

1. Create a new copy of the template directory.
2. Copy file `loc1-vars.tf` into a new file called `loc3-vars.tf`.
3. Edit the newly created `loc3-vars.tf` file and do a global replace of `loc1` with `loc3`, and `Location 1` with `Location 3`.
4. Edit the `main.tf`, and make a copy of the following section:

```
# Location 1; creates vTM Location and Monitor(s)
#
module "loc1" {
  source = "mod_location"
  providers = {
    "vtm"           = "vtm"
    "vtm.secondary" = "vtm.secondary"
  }
  env_id            = "${var.env_id}"
  sec_count         = "${local.secondary_count}"
  loc_ips           = "${var.loc1_ips}"
  loc_mon_port      = "443"
  loc_lat           = "${var.loc1_lat}"
  loc_lon           = "${var.loc1_lon}"
  loc_num           = "1"
  monitor_http_path = "${var.monitor_http_path}"
}
```

Paste it under the "Location 2" section, and replace all instances `loc1` in your pasted copy with `loc3`.

5. Edit the `vtm_glb_service` section in `main.tf`, and add another line (with `loc3`) to the `chained_location_order` list:

```
resource "vtm_glb_service" "glb_service" {
  name = "${var.env_id}-GLB-Service-1"

  # If adding more locations, update this:
  chained_location_order = [
    "${module.loc1.loc_name}",
    "${module.loc2.loc_name}",
                                # <<== Add the "loc3" line here
  ]
```

6. While in the same `vtm_glb_service` resource, make a copy of the following section:

```
  # Location 1:
  location_settings {
    location = "${module.loc1.loc_name}"
    ips      = "${var.loc1_ips}"
    monitors = ["${module.loc1.mon_loc_name}"]
  }
```

Paste it underneath the similarly looking "Location 2" section, and replace all instances of `loc1` in your pasted copy with `loc3`.

7. Replicate chanes made in steps (5) and (6) above in the file `main-secondary.tf`.

8. Edit `terraform.tfvars` and add values for `loc3_ips`, `loc3_lat`, and `loc3_lon`.

You should be all set!