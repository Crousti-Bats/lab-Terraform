resource "opnsense_firewall_filter" "lan_to_wan" {
  count       = var.enable_opnsense_config ? 1 : 0
  enabled     = true
  action      = "pass"
  quick       = true
  interface   = ["lan"]
  direction   = "in"
  ip_protocol = "inet"
  protocol    = "any"
  description = "Allow LAN to WAN (any)"

  source = {
    net = "lan"
  }

  destination = {
    net = "any"
  }
}

resource "opnsense_firewall_filter" "fortigate_to_spoke" {
  count       = var.enable_opnsense_config ? length(var.onprem_address_space) : 0
  enabled     = true
  action      = "pass"
  quick       = true
  interface   = ["wan"]
  direction   = "in"
  ip_protocol = "inet"
  protocol    = "any"
  description = "Allow Fortigate ${var.onprem_address_space[count.index]} to Spoke"

  source = {
    net = var.onprem_address_space[count.index]
  }

  destination = {
    net = var.spoke_vnet_cidr
  }
}
