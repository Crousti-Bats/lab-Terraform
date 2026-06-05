variable "subscription_id" {
  type        = string
  description = "ID de la souscription Azure cible."
}

variable "prefix" {
  type    = string
  default = "lab"
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "resource_group_name" {
  type    = string
  default = "rg_lab_agi"
}

variable "tags" {
  type = map(string)
  default = {
    project     = "lab-terraform"
    environment = "lab"
    managed_by  = "terraform"
  }
}

variable "hub_vnet_cidr" {
  type    = string
  default = "172.16.100.0/24"
}

variable "spoke_vnet_cidr" {
  type    = string
  default = "172.16.104.0/24"
}

variable "subnet_gateway_cidr" {
  type    = string
  default = "172.16.100.0/27"
}

variable "subnet_lan_cidr" {
  type    = string
  default = "172.16.100.64/28"
}

variable "subnet_wan_cidr" {
  type    = string
  default = "172.16.100.80/28"
}

variable "subnet_mgmt_cidr" {
  type    = string
  default = "172.16.100.96/28"
}

variable "subnet_test_cidr" {
  type    = string
  default = "172.16.104.0/27"
}

variable "opnsense_wan_ip" {
  type    = string
  default = "172.16.100.84"
}

variable "opnsense_lan_ip" {
  type    = string
  default = "172.16.100.68"
}

variable "opnsense_mgmt_ip" {
  type    = string
  default = "172.16.100.100"
}

variable "fortigate_public_ip" {
  type    = string
  default = "195.46.235.220"
}

variable "onprem_address_space" {
  type    = list(string)
  default = ["10.118.255.0/24"]
}

variable "vpn_psk" {
  type      = string
  sensitive = true
}

variable "opnsense_admin_username" {
  type    = string
  default = "opnadmin"
}

variable "opnsense_admin_password" {
  type      = string
  sensitive = true
}

variable "spoke_vm_admin_username" {
  type    = string
  default = "azureuser"
}

variable "spoke_vm_admin_password" {
  type      = string
  sensitive = true
}

variable "opnsense_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
    plan      = string
  })
  default = {
    publisher = "decisosalesbv"
    offer     = "opnsense"
    sku       = "opnsense-be-2025"
    version   = "26.1.6"
    plan      = "opnsense-be-2025"
  }
}

variable "opnsense_vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "spoke_vm_size" {
  type    = string
  default = "Standard_B1s"
}

variable "accept_marketplace_terms" {
  type    = bool
  default = false
}

variable "opnsense_url" {
  type    = string
  default = ""
}

variable "opnsense_api_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "opnsense_api_secret" {
  type      = string
  sensitive = true
  default   = ""
}

variable "enable_opnsense_config" {
  type    = bool
  default = false
}

variable "mgmt_allowed_source" {
  type    = string
  default = "*"
}

variable "allowed_ssh_source" {
  type        = string
  description = "IP autorisee en SSH sur la VM Ubuntu spoke."
  default     = "*"
}
