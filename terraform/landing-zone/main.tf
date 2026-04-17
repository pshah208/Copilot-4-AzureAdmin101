################################################################################
# Resource Groups
################################################################################

resource "azurerm_resource_group" "hub_networking" {
  name     = "rg-hub-networking-${var.environment}-${var.location}-001"
  location = var.location
}

resource "azurerm_resource_group" "management" {
  name     = "rg-management-${var.environment}-${var.location}-001"
  location = var.location
}

resource "azurerm_resource_group" "security" {
  name     = "rg-security-${var.environment}-${var.location}-001"
  location = var.location
}

resource "azurerm_resource_group" "spoke" {
  for_each = var.spokes
  name     = "rg-spoke-${each.key}-${var.environment}-${var.location}-001"
  location = var.location
}

################################################################################
# Log Analytics Workspace (centralised monitoring)
################################################################################

resource "azurerm_log_analytics_workspace" "central" {
  name                = "log-central-${var.environment}-${var.location}-001"
  resource_group_name = azurerm_resource_group.management.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days
}

################################################################################
# Hub Network Module
################################################################################

module "hub_network" {
  source = "./modules/hub-network"

  resource_group_name            = azurerm_resource_group.hub_networking.name
  location                       = var.location
  environment                    = var.environment
  hub_vnet_address_space         = var.hub_vnet_address_space
  gateway_subnet_prefix          = var.hub_gateway_subnet_prefix
  firewall_subnet_prefix         = var.hub_firewall_subnet_prefix
  management_subnet_prefix       = var.hub_management_subnet_prefix
  bastion_subnet_prefix          = var.hub_bastion_subnet_prefix
  enable_vpn_gateway             = var.enable_vpn_gateway
  enable_expressroute_gateway    = var.enable_expressroute_gateway
  enable_ddos_protection         = var.enable_ddos_protection
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.central.id
}

################################################################################
# Spoke Network Modules
################################################################################

module "spoke_network" {
  for_each = var.spokes
  source   = "./modules/spoke-network"

  resource_group_name        = azurerm_resource_group.spoke[each.key].name
  location                   = var.location
  environment                = var.environment
  spoke_name                 = each.key
  address_space              = each.value.address_space
  workload_subnets           = each.value.workload_subnets
  hub_vnet_id                = module.hub_network.hub_vnet_id
  hub_vnet_name              = module.hub_network.hub_vnet_name
  hub_resource_group_name    = azurerm_resource_group.hub_networking.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id
}

################################################################################
# Policy Module
################################################################################

module "policy" {
  source = "./modules/policy"

  environment                = var.environment
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id
}

################################################################################
# Microsoft Defender for Cloud
################################################################################

resource "azurerm_security_center_subscription_pricing" "defender_servers" {
  count         = var.enable_defender_for_cloud ? 1 : 0
  tier          = "Standard"
  resource_type = "VirtualMachines"
}

resource "azurerm_security_center_subscription_pricing" "defender_storage" {
  count         = var.enable_defender_for_cloud ? 1 : 0
  tier          = "Standard"
  resource_type = "StorageAccounts"
}

resource "azurerm_security_center_subscription_pricing" "defender_keyvault" {
  count         = var.enable_defender_for_cloud ? 1 : 0
  tier          = "Standard"
  resource_type = "KeyVaults"
}

resource "azurerm_security_center_workspace" "central" {
  count        = var.enable_defender_for_cloud ? 1 : 0
  scope        = "/subscriptions/${var.subscription_id}"
  workspace_id = azurerm_log_analytics_workspace.central.id
}
