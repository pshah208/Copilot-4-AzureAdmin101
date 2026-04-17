variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "environment"         { type = string }
variable "hub_vnet_address_space"      { type = list(string) }
variable "gateway_subnet_prefix"       { type = string }
variable "firewall_subnet_prefix"      { type = string }
variable "management_subnet_prefix"    { type = string }
variable "bastion_subnet_prefix"       { type = string }
variable "enable_vpn_gateway"          { type = bool; default = false }
variable "enable_expressroute_gateway" { type = bool; default = false }
variable "enable_ddos_protection"      { type = bool; default = false }
variable "log_analytics_workspace_id"  { type = string }
