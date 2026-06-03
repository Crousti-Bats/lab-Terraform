output "gateway_id" {
  value = azurerm_virtual_network_gateway.this.id
}

output "gateway_public_ip" {
  value = azurerm_public_ip.vpn.ip_address
}
