variable "prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

variable "test_subnet_id" { type = string }
variable "onprem_address_space" { type = list(string) }
variable "opnsense_lan_ip" { type = string }
