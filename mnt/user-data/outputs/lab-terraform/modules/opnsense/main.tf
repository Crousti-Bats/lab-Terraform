resource "azurerm_marketplace_agreement" "opnsense" {
  publisher = var.image.publisher
  offer     = var.image.offer
  plan      = var.image.sku
}

resource "azurerm_public_ip" "wan" {
  name                = "${var.prefix}-pip-opn-wan"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "mgmt" {
  name                = "${var.prefix}-pip-opn-mgmt"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "wan" {
  name                  = "${var.prefix}-nic-opn-wan"
  location              = var.location
  resource_group_name   = var.resource_group_name
  ip_forwarding_enabled = true
  tags                  = var.tags

  ip_configuration {
    name                          = "ipconfig-wan"
    subnet_id                     = var.wan_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.wan_ip
    public_ip_address_id          = azurerm_public_ip.wan.id
  }
}

resource "azurerm_network_interface" "lan" {
  name                  = "${var.prefix}-nic-opn-lan"
  location              = var.location
  resource_group_name   = var.resource_group_name
  ip_forwarding_enabled = true
  tags                  = var.tags

  ip_configuration {
    name                          = "ipconfig-lan"
    subnet_id                     = var.lan_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.lan_ip
  }
}

resource "azurerm_network_interface" "mgmt" {
  name                  = "${var.prefix}-nic-opn-mgmt"
  location              = var.location
  resource_group_name   = var.resource_group_name
  ip_forwarding_enabled = true
  tags                  = var.tags

  ip_configuration {
    name                          = "ipconfig-mgmt"
    subnet_id                     = var.mgmt_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.mgmt_ip
    public_ip_address_id          = azurerm_public_ip.mgmt.id
  }
}

resource "azurerm_network_security_group" "mgmt" {
  name                = "${var.prefix}-nsg-opn-mgmt"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "allow-https-mgmt"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.mgmt_allowed_source
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh-mgmt"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.mgmt_allowed_source
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "mgmt" {
  network_interface_id      = azurerm_network_interface.mgmt.id
  network_security_group_id = azurerm_network_security_group.mgmt.id
}

resource "azurerm_linux_virtual_machine" "opnsense" {
  name                            = "${var.prefix}-vm-opnsense"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  tags                            = var.tags

  network_interface_ids = [
    azurerm_network_interface.wan.id,
    azurerm_network_interface.lan.id,
    azurerm_network_interface.mgmt.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }

  plan {
    publisher = var.image.publisher
    product   = var.image.offer
    name      = var.image.sku
  }

  depends_on = [azurerm_marketplace_agreement.opnsense]
}
