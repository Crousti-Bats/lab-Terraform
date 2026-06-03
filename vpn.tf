# ---------- VPN Gateway ----------
resource "azurerm_public_ip" "vng" {
  name                = "pip-${var.prefix}-vng"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "hub" {
  name                = "vng-${var.prefix}-hub"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
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

# ---------- On-premise (Fortigate) ----------
resource "azurerm_local_network_gateway" "onprem" {
  name                = "lng-${var.prefix}-onprem"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  gateway_address     = var.onprem_gateway_address
  address_space       = var.onprem_address_space
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway_connection" "onprem" {
  name                       = "cn-${var.prefix}-onprem"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  type                       = "IPsec"
  connection_protocol        = "IKEv2"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.hub.id
  local_network_gateway_id   = azurerm_local_network_gateway.onprem.id
  shared_key                 = var.vpn_shared_key
  tags                       = var.tags

  # One single proposal allowed by Azure: must match the Fortigate exactly.
  ipsec_policy {
    # Phase 1 (IKE)
    ike_encryption = "AES256"
    ike_integrity  = "SHA256" # swap to "SHA384" if needed (match Fortigate)
    dh_group       = "ECP384" # DH group 20

    # Phase 2 (IPsec / ESP)
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA384"
    pfs_group        = "ECP384" # PFS group 20
    sa_lifetime      = 27000
  }
}
