resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.prefix}-hub"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  address_space       = [var.hub_vnet_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_gateway_cidr]
}

resource "azurerm_subnet" "lan" {
  name                 = "snet-lan"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_lan_cidr]
}

resource "azurerm_subnet" "wan" {
  name                 = "snet-wan"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_wan_cidr]
}

resource "azurerm_subnet" "mgmt" {
  name                 = "snet-mgmt"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_mgmt_cidr]
}
