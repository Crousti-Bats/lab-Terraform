resource "azurerm_public_ip" "vpn" {
  name                = "${var.prefix}-pip-vpngw"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = "${var.prefix}-vpngw"
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  generation          = "Generation1"
  active_active       = false
  enable_bgp          = false
  tags                = var.tags

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }
}

resource "azurerm_local_network_gateway" "fortigate" {
  name                = "${var.prefix}-lng-fortigate"
  location            = var.location
  resource_group_name = var.resource_group_name
  gateway_address     = var.fortigate_public_ip
  address_space       = var.onprem_address_space
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway_connection" "ipsec" {
  name                = "${var.prefix}-cnx-fortigate"
  location            = var.location
  resource_group_name = var.resource_group_name

  type                       = "IPsec"
  connection_protocol        = "IKEv2"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  local_network_gateway_id   = azurerm_local_network_gateway.fortigate.id
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
