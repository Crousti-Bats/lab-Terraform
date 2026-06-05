resource "azurerm_marketplace_agreement" "opnsense" {
  count     = var.accept_marketplace_terms ? 1 : 0
  publisher = var.opnsense_image.publisher
  offer     = var.opnsense_image.offer
  plan      = var.opnsense_image.plan
}

resource "azurerm_public_ip" "opn_wan" {
  name                = "pip-${var.prefix}-opn-wan"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "opn_mgmt" {
  name                = "pip-${var.prefix}-opn-mgmt"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "opn_wan" {
  name                  = "nic-${var.prefix}-opn-wan"
  resource_group_name   = data.azurerm_resource_group.main.name
  location              = data.azurerm_resource_group.main.location
  ip_forwarding_enabled = true
  tags                  = var.tags

  ip_configuration {
    name                          = "wan"
    subnet_id                     = azurerm_subnet.wan.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.opnsense_wan_ip
    public_ip_address_id          = azurerm_public_ip.opn_wan.id
  }
}

resource "azurerm_network_interface" "opn_lan" {
  name                  = "nic-${var.prefix}-opn-lan"
  resource_group_name   = data.azurerm_resource_group.main.name
  location              = data.azurerm_resource_group.main.location
  ip_forwarding_enabled = true
  tags                  = var.tags

  ip_configuration {
    name                          = "lan"
    subnet_id                     = azurerm_subnet.lan.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.opnsense_lan_ip
  }
}

resource "azurerm_network_interface" "opn_mgmt" {
  name                  = "nic-${var.prefix}-opn-mgmt"
  resource_group_name   = data.azurerm_resource_group.main.name
  location              = data.azurerm_resource_group.main.location
  ip_forwarding_enabled = true
  tags                  = var.tags

  ip_configuration {
    name                          = "mgmt"
    subnet_id                     = azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.opnsense_mgmt_ip
    public_ip_address_id          = azurerm_public_ip.opn_mgmt.id
  }
}

resource "azurerm_network_security_group" "opn_mgmt" {
  name                = "nsg-${var.prefix}-opn-mgmt"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  tags                = var.tags

  security_rule {
    name                       = "allow-https"
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
    name                       = "allow-ssh"
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

resource "azurerm_network_interface_security_group_association" "opn_mgmt" {
  network_interface_id      = azurerm_network_interface.opn_mgmt.id
  network_security_group_id = azurerm_network_security_group.opn_mgmt.id
}

resource "azurerm_linux_virtual_machine" "opnsense" {
  name                            = "vm-${var.prefix}-opnsense"
  resource_group_name             = data.azurerm_resource_group.main.name
  location                        = data.azurerm_resource_group.main.location
  size                            = var.opnsense_vm_size
  admin_username                  = var.opnsense_admin_username
  admin_password                  = var.opnsense_admin_password
  disable_password_authentication = false
  tags                            = var.tags

  network_interface_ids = [
    azurerm_network_interface.opn_wan.id,
    azurerm_network_interface.opn_lan.id,
    azurerm_network_interface.opn_mgmt.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.opnsense_image.publisher
    offer     = var.opnsense_image.offer
    sku       = var.opnsense_image.sku
    version   = var.opnsense_image.version
  }

  plan {
    publisher = var.opnsense_image.publisher
    product   = var.opnsense_image.offer
    name      = var.opnsense_image.plan
  }

  depends_on = [azurerm_marketplace_agreement.opnsense]
}
