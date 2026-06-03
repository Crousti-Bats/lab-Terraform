variable "prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

variable "wan_subnet_id" { type = string }
variable "lan_subnet_id" { type = string }
variable "mgmt_subnet_id" { type = string }

variable "wan_ip" { type = string }
variable "lan_ip" { type = string }
variable "mgmt_ip" { type = string }

variable "admin_username" { type = string }
variable "admin_password" {
  type      = string
  sensitive = true
}

variable "vm_size" { type = string }

variable "image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "mgmt_allowed_source" { type = string }
