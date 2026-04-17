output "spoke_vnet_id"   { value = azurerm_virtual_network.spoke.id }
output "spoke_vnet_name" { value = azurerm_virtual_network.spoke.name }
output "subnet_ids"      { value = { for k, v in azurerm_subnet.workload : k => v.id } }
