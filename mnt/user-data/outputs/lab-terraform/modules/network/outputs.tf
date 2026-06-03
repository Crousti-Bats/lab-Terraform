output "hub_vnet_id" {
  value = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  value = azurerm_virtual_network.hub.name
}

output "spoke_vnet_id" {
  value = azurerm_virtual_network.spoke.id
}

output "spoke_vnet_name" {
  value = azurerm_virtual_network.spoke.name
}

output "gateway_subnet_id" {
  value = azurerm_subnet.gateway.id
}

output "lan_subnet_id" {
  value = azurerm_subnet.lan.id
}

output "wan_subnet_id" {
  value = azurerm_subnet.wan.id
}

output "mgmt_subnet_id" {
  value = azurerm_subnet.mgmt.id
}

output "test_subnet_id" {
  value = azurerm_subnet.test.id
}
