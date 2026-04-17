output "hub_vnet_id" {
  description = "Resource ID of the hub virtual network."
  value       = module.hub_network.hub_vnet_id
}

output "hub_vnet_name" {
  description = "Name of the hub virtual network."
  value       = module.hub_network.hub_vnet_name
}

output "hub_firewall_private_ip" {
  description = "Private IP address of the Azure Firewall in the hub."
  value       = module.hub_network.firewall_private_ip
}

output "spoke_vnet_ids" {
  description = "Map of spoke name to spoke VNet resource IDs."
  value       = { for k, v in module.spoke_network : k => v.spoke_vnet_id }
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the central Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.central.id
}

output "log_analytics_workspace_key" {
  description = "Primary shared key of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.central.primary_shared_key
  sensitive   = true
}

output "management_resource_group_name" {
  description = "Name of the management resource group."
  value       = azurerm_resource_group.management.name
}
