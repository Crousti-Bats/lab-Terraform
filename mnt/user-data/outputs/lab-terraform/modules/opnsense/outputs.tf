output "mgmt_public_ip" {
  value = azurerm_public_ip.mgmt.ip_address
}

output "wan_public_ip" {
  value = azurerm_public_ip.wan.ip_address
}

output "lan_private_ip" {
  value = azurerm_network_interface.lan.private_ip_address
}
