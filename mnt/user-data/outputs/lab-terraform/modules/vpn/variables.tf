variable "prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

variable "gateway_subnet_id" { type = string }
variable "fortigate_public_ip" { type = string }
variable "onprem_address_space" { type = list(string) }

variable "vpn_psk" {
  type      = string
  sensitive = true
}
