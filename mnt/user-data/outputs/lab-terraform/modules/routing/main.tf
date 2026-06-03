resource "azurerm_route_table" "test" {
  name                = "${var.prefix}-rt-test"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_route" "to_onprem" {
  count                  = length(var.onprem_address_space)
  name                   = "to-onprem-${count.index}"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.test.name
  address_prefix         = var.onprem_address_space[count.index]
  next_hop_type          = "VirtualNetworkGateway"
}

resource "azurerm_route" "default_via_opnsense" {
  name                   = "default-via-opnsense"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.test.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.opnsense_lan_ip
}

resource "azurerm_subnet_route_table_association" "test" {
  subnet_id      = var.test_subnet_id
  route_table_id = azurerm_route_table.test.id
}
