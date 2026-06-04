output "resource_group" {
  value = data.azurerm_resource_group.this.name
}

output "vpn_gateway_public_ip" {
  description = "IP publique du VPN Gateway (a configurer cote Fortigate)."
  value       = module.vpn.gateway_public_ip
}

output "opnsense_mgmt_public_ip" {
  description = "IP publique de management OPNsense (acces GUI/API)."
  value       = module.opnsense.mgmt_public_ip
}

output "opnsense_wan_public_ip" {
  value = module.opnsense.wan_public_ip
}

output "spoke_vm_private_ip" {
  value = module.spoke_vm.private_ip
}
