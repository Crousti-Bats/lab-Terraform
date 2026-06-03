resource "azurerm_virtual_network" "hub" {
  name                = "${var.prefix}-vnet-hub"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.hub_vnet_cidr]
  tags                = var.tags
}

resource "azurerm_virtual_network" "spoke" {
  name                = "${var.prefix}-vnet-test"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.spoke_vnet_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_gateway_cidr]
}

resource "azurerm_subnet" "lan" {
  name                 = "snet-lan"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_lan_cidr]
}

resource "azurerm_subnet" "wan" {
  name                 = "snet-wan"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_wan_cidr]
}

resource "azurerm_subnet" "mgmt" {
  name                 = "snet-mgmt"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_mgmt_cidr]
}

resource "azurerm_subnet" "test" {
  name                 = "snet-test"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.subnet_test_cidr]
}

