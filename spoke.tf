resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-${var.prefix}-spoke-test"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  address_space       = [var.spoke_vnet_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "spoke_test" {
  name                 = "snet-test"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.subnet_test_cidr]
}

resource "azurerm_network_security_group" "spoke" {
  name                = "nsg-${var.prefix}-spoke-test"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  tags                = var.tags

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_source
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-icmp-onprem"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = var.onprem_address_space
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "spoke" {
  subnet_id                 = azurerm_subnet.spoke_test.id
  network_security_group_id = azurerm_network_security_group.spoke.id
}

resource "azurerm_public_ip" "ubuntu" {
  name                = "pip-${var.prefix}-ubuntu"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "ubuntu" {
  name                = "nic-${var.prefix}-ubuntu"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke_test.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.16.104.4"
    public_ip_address_id          = azurerm_public_ip.ubuntu.id
  }
}

resource "azurerm_linux_virtual_machine" "ubuntu" {
  name                            = "vm-${var.prefix}-ubuntu-test"
  resource_group_name             = data.azurerm_resource_group.main.name
  location                        = data.azurerm_resource_group.main.location
  size                            = var.spoke_vm_size
  admin_username                  = var.spoke_vm_admin_username
  admin_password                  = var.spoke_vm_admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.ubuntu.id]
  tags                            = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}
