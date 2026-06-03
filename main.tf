locals {
  hub_address_space   = "172.16.100.0/24"
  spoke_address_space = "172.16.104.0/24"

  hub_subnets = {
    gateway     = "172.16.100.0/27"  # GatewaySubnet
    routeserver = "172.16.100.32/27" # RouteServerSubnet
    lan         = "172.16.100.64/28" # snet-lan
    wan         = "172.16.100.80/28" # snet-wan
    mgmt        = "172.16.100.96/28" # snet-mgmt
  }

  spoke_subnet = "172.16.104.0/28" # snet-test
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.prefix}-hubspoke"
  location = var.location
  tags     = var.tags
}
