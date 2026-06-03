# ---------- Spoke VNet & subnet ----------
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-${var.prefix}-spoke-test"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = [local.spoke_address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "spoke_test" {
  name                 = "snet-test"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [local.spoke_subnet]
}

# ---------- Bidirectional peering ----------
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "peer-hub-to-spoke"
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-spoke-to-hub"
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
  depends_on                   = [azurerm_virtual_network_gateway.hub]
}

# ---------- Ubuntu VM ----------
resource "azurerm_network_security_group" "spoke" {
  name                = "nsg-${var.prefix}-spoke-test"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = var.tags

  security_rule {
    name                       = "Allow-SSH"
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
    name                       = "Allow-ICMP-OnPrem"
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
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "ubuntu" {
  name                = "nic-${var.prefix}-ubuntu"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
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
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_B1s"
  admin_username                  = var.linux_admin_username
  admin_password                  = var.linux_admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.ubuntu.id]

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

  tags = var.tags
}
