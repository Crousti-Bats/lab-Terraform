variable "prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

variable "hub_vnet_cidr" { type = string }
variable "spoke_vnet_cidr" { type = string }
variable "subnet_gateway_cidr" { type = string }
variable "subnet_lan_cidr" { type = string }
variable "subnet_wan_cidr" { type = string }
variable "subnet_mgmt_cidr" { type = string }
variable "subnet_test_cidr" { type = string }
