################################################################################
# Global variables
################################################################################

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID where the landing zone is deployed."
}

variable "tenant_id" {
  type        = string
  description = "Azure AD / Entra ID tenant ID."
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev | staging | prod)."
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  type        = string
  description = "Primary Azure region for the landing zone (e.g. eastus)."
  default     = "eastus"
}

variable "cost_center" {
  type        = string
  description = "Cost centre code for tagging and charge-back."
}

variable "owner" {
  type        = string
  description = "Team or individual responsible for this landing zone."
}

################################################################################
# Hub network variables
################################################################################

variable "hub_vnet_address_space" {
  type        = list(string)
  description = "Address space for the hub virtual network."
  default     = ["10.0.0.0/16"]
}

variable "hub_gateway_subnet_prefix" {
  type        = string
  description = "Address prefix for GatewaySubnet (must be /27 or larger)."
  default     = "10.0.0.0/27"
}

variable "hub_firewall_subnet_prefix" {
  type        = string
  description = "Address prefix for AzureFirewallSubnet (must be /26 or larger)."
  default     = "10.0.1.0/26"
}

variable "hub_management_subnet_prefix" {
  type        = string
  description = "Address prefix for the management/jump-host subnet."
  default     = "10.0.2.0/24"
}

variable "hub_bastion_subnet_prefix" {
  type        = string
  description = "Address prefix for AzureBastionSubnet (must be /26 or larger)."
  default     = "10.0.3.0/26"
}

variable "enable_vpn_gateway" {
  type        = bool
  description = "Deploy a VPN Gateway in the hub. Set to false when using ExpressRoute only."
  default     = false
}

variable "enable_expressroute_gateway" {
  type        = bool
  description = "Deploy an ExpressRoute Gateway in the hub."
  default     = false
}

################################################################################
# Spoke network variables
################################################################################

variable "spokes" {
  type = map(object({
    address_space    = list(string)
    workload_subnets = map(string) # name → CIDR
  }))
  description = "Map of spoke virtual networks to peer with the hub."
  default = {
    "workload-a" = {
      address_space = ["10.10.0.0/16"]
      workload_subnets = {
        "snet-app"  = "10.10.1.0/24"
        "snet-data" = "10.10.2.0/24"
      }
    }
    "workload-b" = {
      address_space = ["10.20.0.0/16"]
      workload_subnets = {
        "snet-app" = "10.20.1.0/24"
      }
    }
  }
}

################################################################################
# Security & monitoring variables
################################################################################

variable "log_analytics_retention_days" {
  type        = number
  description = "Retention period in days for the Log Analytics Workspace."
  default     = 90
}

variable "enable_defender_for_cloud" {
  type        = bool
  description = "Enable Microsoft Defender for Cloud on the subscription."
  default     = true
}

variable "enable_ddos_protection" {
  type        = bool
  description = "Enable Azure DDoS Network Protection on the hub VNet."
  default     = false
}
