output "vng_public_ip" {
  description = "Public IP of the Azure VPN Gateway (use this on the Fortigate)"
  value       = azurerm_public_ip.vng.ip_address
}

output "route_server_bgp_ips" {
  description = "Route Server BGP peer IPs (expected ~172.16.100.36, assigned by Azure)"
  value       = azurerm_route_server.hub.virtual_router_ips
}

output "palo_alto_mgmt_public_ip" {
  description = "Public IP of the Palo Alto management interface"
  value       = azurerm_public_ip.pa_mgmt.ip_address
}

output "palo_alto_wan_public_ip" {
  description = "Public IP of the Palo Alto WAN interface"
  value       = azurerm_public_ip.pa_wan.ip_address
}

output "ubuntu_public_ip" {
  description = "Public IP of the Ubuntu spoke VM"
  value       = azurerm_public_ip.ubuntu.ip_address
}

output "ubuntu_private_ip" {
  description = "Private IP of the Ubuntu VM (the address you ping from on-premise)"
  value       = azurerm_network_interface.ubuntu.private_ip_address
}
