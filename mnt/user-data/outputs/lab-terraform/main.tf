data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

module "network" {
  source = "./modules/network"

  prefix              = var.prefix
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  tags                = var.tags

  hub_vnet_cidr       = var.hub_vnet_cidr
  spoke_vnet_cidr     = var.spoke_vnet_cidr
  subnet_gateway_cidr = var.subnet_gateway_cidr
  subnet_lan_cidr     = var.subnet_lan_cidr
  subnet_wan_cidr     = var.subnet_wan_cidr
  subnet_mgmt_cidr    = var.subnet_mgmt_cidr
  subnet_test_cidr    = var.subnet_test_cidr
}

module "vpn" {
  source = "./modules/vpn"

  prefix              = var.prefix
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  tags                = var.tags

  gateway_subnet_id    = module.network.gateway_subnet_id
  fortigate_public_ip  = var.fortigate_public_ip
  onprem_address_space = var.onprem_address_space
  vpn_psk              = var.vpn_psk
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "peer-hub-to-spoke"
  resource_group_name          = data.azurerm_resource_group.this.name
  virtual_network_name         = module.network.hub_vnet_name
  remote_virtual_network_id    = module.network.spoke_vnet_id
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  allow_virtual_network_access = true

  depends_on = [module.vpn]
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-spoke-to-hub"
  resource_group_name          = data.azurerm_resource_group.this.name
  virtual_network_name         = module.network.spoke_vnet_name
  remote_virtual_network_id    = module.network.hub_vnet_id
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
  allow_virtual_network_access = true

  depends_on = [module.vpn, azurerm_virtual_network_peering.hub_to_spoke]
}

module "opnsense" {
  source = "./modules/opnsense"

  prefix              = var.prefix
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  tags                = var.tags

  wan_subnet_id  = module.network.wan_subnet_id
  lan_subnet_id  = module.network.lan_subnet_id
  mgmt_subnet_id = module.network.mgmt_subnet_id

  wan_ip  = var.opnsense_wan_ip
  lan_ip  = var.opnsense_lan_ip
  mgmt_ip = var.opnsense_mgmt_ip

  admin_username      = var.opnsense_admin_username
  admin_password      = var.opnsense_admin_password
  vm_size             = var.opnsense_vm_size
  image               = var.opnsense_image
  mgmt_allowed_source = var.mgmt_allowed_source

  accept_marketplace_terms = var.accept_marketplace_terms
}

module "spoke_vm" {
  source = "./modules/spoke-vm"

  prefix              = var.prefix
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  tags                = var.tags

  subnet_id      = module.network.test_subnet_id
  vm_size        = var.spoke_vm_size
  admin_username = var.spoke_vm_admin_username
  admin_password = var.spoke_vm_admin_password
}

module "routing" {
  source = "./modules/routing"

  prefix              = var.prefix
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  tags                = var.tags

  test_subnet_id       = module.network.test_subnet_id
  onprem_address_space = var.onprem_address_space
  opnsense_lan_ip      = var.opnsense_lan_ip
}

module "opnsense_config" {
  source = "./modules/opnsense-config"
  count  = var.enable_opnsense_config ? 1 : 0

  spoke_cidr           = var.spoke_vnet_cidr
  onprem_address_space = var.onprem_address_space
}
