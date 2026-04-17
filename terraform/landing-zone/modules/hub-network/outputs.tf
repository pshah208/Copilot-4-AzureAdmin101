output "hub_vnet_id"         { value = azurerm_virtual_network.hub.id }
output "hub_vnet_name"       { value = azurerm_virtual_network.hub.name }
output "firewall_private_ip" { value = azurerm_firewall.hub.ip_configuration[0].private_ip_address }
output "gateway_subnet_id"   { value = azurerm_subnet.gateway.id }
output "management_subnet_id"{ value = azurerm_subnet.management.id }
