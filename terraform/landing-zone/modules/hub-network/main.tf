################################################################################
# Hub Virtual Network
################################################################################

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.environment}-${var.location}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.hub_vnet_address_space

  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection ? [azurerm_network_ddos_protection_plan.hub[0].id] : []
    content {
      id     = ddos_protection_plan.value
      enable = true
    }
  }
}

resource "azurerm_network_ddos_protection_plan" "hub" {
  count               = var.enable_ddos_protection ? 1 : 0
  name                = "ddos-hub-${var.environment}-${var.location}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
}

################################################################################
# Subnets
################################################################################

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.gateway_subnet_prefix]
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.firewall_subnet_prefix]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.bastion_subnet_prefix]
}

resource "azurerm_subnet" "management" {
  name                 = "snet-management-${var.environment}-001"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.management_subnet_prefix]
}

################################################################################
# Azure Firewall
################################################################################

resource "azurerm_public_ip" "firewall" {
  name                = "pip-fw-hub-${var.environment}-${var.location}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

resource "azurerm_firewall" "hub" {
  name                = "afw-hub-${var.environment}-${var.location}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  zones               = ["1", "2", "3"]

  ip_configuration {
    name                 = "ipconfig-hub"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                       = "diag-afw-hub"
  target_resource_id         = azurerm_firewall.hub.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "AzureFirewallApplicationRule" }
  enabled_log { category = "AzureFirewallNetworkRule" }
  enabled_log { category = "AzureFirewallDnsProxy" }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

################################################################################
# Azure Bastion
################################################################################

resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion-hub-${var.environment}-${var.location}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

resource "azurerm_bastion_host" "hub" {
  name                = "bas-hub-${var.environment}-${var.location}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"

  ip_configuration {
    name                 = "ipconfig-bastion"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

################################################################################
# VPN Gateway (optional)
################################################################################

resource "azurerm_public_ip" "vpn_gateway" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "pip-vpngw-hub-${var.environment}-${var.location}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

resource "azurerm_virtual_network_gateway" "vpn" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "vpngw-hub-${var.environment}-${var.location}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw2AZ"
  generation          = "Generation2"
  enable_bgp          = true
  active_active       = false

  ip_configuration {
    name                          = "ipconfig-vpngw"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }
}

################################################################################
# VNet Diagnostic Settings
################################################################################

resource "azurerm_monitor_diagnostic_setting" "hub_vnet" {
  name                       = "diag-vnet-hub"
  target_resource_id         = azurerm_virtual_network.hub.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
