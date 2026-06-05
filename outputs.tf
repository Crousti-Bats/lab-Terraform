output "resource_group" {
  value = data.azurerm_resource_group.main.name
}

output "vpn_gateway_public_ip" {
  description = "IP publique du VPN Gateway (a configurer cote Fortigate)."
  value       = azurerm_public_ip.vng.ip_address
}

output "opnsense_mgmt_public_ip" {
  description = "IP publique de management OPNsense (acces GUI/API)."
  value       = azurerm_public_ip.opn_mgmt.ip_address
}

output "opnsense_wan_public_ip" {
  value = azurerm_public_ip.opn_wan.ip_address
}

output "spoke_vm_private_ip" {
  value = azurerm_network_interface.ubuntu.private_ip_address
}

output "spoke_vm_public_ip" {
  value = azurerm_public_ip.ubuntu.ip_address
}
