resource "opnsense_firewall_filter" "lan_to_wan" {
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
  count = length(var.onprem_address_space)

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
    net = var.spoke_cidr
  }
}
