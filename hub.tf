# ---------- Hub VNet & subnets ----------
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.prefix}-hub"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = [local.hub_address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.hub_subnets.gateway]
}

resource "azurerm_subnet" "routeserver" {
  name                 = "RouteServerSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.hub_subnets.routeserver]
}

resource "azurerm_subnet" "lan" {
  name                 = "snet-lan"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.hub_subnets.lan]
}

resource "azurerm_subnet" "wan" {
  name                 = "snet-wan"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.hub_subnets.wan]
}

resource "azurerm_subnet" "mgmt" {
  name                 = "snet-mgmt"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.hub_subnets.mgmt]
}

# ---------- Azure Route Server ----------
resource "azurerm_public_ip" "route_server" {
  name                = "pip-${var.prefix}-rs"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_route_server" "hub" {
  name                             = "rs-${var.prefix}-hub"
  resource_group_name              = azurerm_resource_group.main.name
  location                         = azurerm_resource_group.main.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.route_server.id
  subnet_id                        = azurerm_subnet.routeserver.id
  branch_to_branch_traffic_enabled = true
  tags                             = var.tags
}

# ---------- Palo Alto marketplace agreement ----------
resource "azurerm_marketplace_agreement" "palo_alto" {
  count     = var.accept_marketplace_agreement ? 1 : 0
  publisher = "paloaltonetworks"
  offer     = "vmseries-flex"
  plan      = var.palo_alto_sku
}

# ---------- Palo Alto NICs (mgmt = primary, then wan, then lan) ----------
resource "azurerm_public_ip" "pa_mgmt" {
  name                = "pip-${var.prefix}-pa-mgmt"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "pa_wan" {
  name                = "pip-${var.prefix}-pa-wan"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "pa_mgmt" {
  name                = "nic-${var.prefix}-pa-mgmt"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = var.tags

  ip_configuration {
    name                          = "mgmt"
    subnet_id                     = azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pa_mgmt.id
  }
}

resource "azurerm_network_interface" "pa_wan" {
  name                  = "nic-${var.prefix}-pa-wan"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  ip_forwarding_enabled = true
  tags                  = var.tags

  ip_configuration {
    name                          = "wan"
    subnet_id                     = azurerm_subnet.wan.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pa_wan.id
  }
}

resource "azurerm_network_interface" "pa_lan" {
  name                  = "nic-${var.prefix}-pa-lan"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  ip_forwarding_enabled = true
  tags                  = var.tags

  ip_configuration {
    name                          = "lan"
    subnet_id                     = azurerm_subnet.lan.id
    private_ip_address_allocation = "Dynamic"
  }
}

# ---------- Palo Alto VM (deployment only, no PAN-OS config) ----------
resource "azurerm_linux_virtual_machine" "palo_alto" {
  name                            = "vm-${var.prefix}-pa-fw"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.palo_alto_vm_size
  admin_username                  = var.palo_alto_admin_username
  admin_password                  = var.palo_alto_admin_password
  disable_password_authentication = false

  # First NIC is primary (management)
  network_interface_ids = [
    azurerm_network_interface.pa_mgmt.id,
    azurerm_network_interface.pa_wan.id,
    azurerm_network_interface.pa_lan.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries-flex"
    sku       = var.palo_alto_sku
    version   = "latest"
  }

  plan {
    name      = var.palo_alto_sku
    publisher = "paloaltonetworks"
    product   = "vmseries-flex"
  }

  tags       = var.tags
  depends_on = [azurerm_marketplace_agreement.palo_alto]
}
