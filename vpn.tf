resource "azurerm_public_ip" "vng" {
  name                = "pip-${var.prefix}-vng"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "hub" {
  name                = "vng-${var.prefix}-hub"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  generation          = "Generation1"
  active_active       = false
  enable_bgp          = false
  tags                = var.tags

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vng.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }
}

resource "azurerm_local_network_gateway" "onprem" {
  name                = "lng-${var.prefix}-onprem"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  gateway_address     = var.fortigate_public_ip
  address_space       = var.onprem_address_space
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway_connection" "onprem" {
  name                       = "cn-${var.prefix}-onprem"
  resource_group_name        = data.azurerm_resource_group.main.name
  location                   = data.azurerm_resource_group.main.location
  type                       = "IPsec"
  connection_protocol        = "IKEv2"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.hub.id
  local_network_gateway_id   = azurerm_local_network_gateway.onprem.id
  shared_key                 = var.vpn_psk
  tags                       = var.tags

  ipsec_policy {
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    dh_group         = "DHGroup14"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "PFS2048"
    sa_lifetime      = 28800
  }
}
