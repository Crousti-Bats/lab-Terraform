output "private_ip" {
  value = azurerm_network_interface.test.private_ip_address
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.test.id
}
