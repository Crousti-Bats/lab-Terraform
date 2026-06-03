variable "subscription_id" {
  type        = string
  description = "ID de la souscription Azure cible."
}

variable "prefix" {
  type        = string
  description = "Prefixe applique a toutes les ressources."
  default     = "lab"
}

variable "location" {
  type        = string
  description = "Region Azure."
  default     = "westeurope"
}

variable "resource_group_name" {
  type        = string
  description = "Nom du resource group."
  default     = "rg-lab-terraform"
}

variable "tags" {
  type        = map(string)
  description = "Tags communs."
  default = {
    project     = "lab-terraform"
    environment = "lab"
    managed_by  = "terraform"
  }
}

# --- Adressage ---

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

# IPs statiques des interfaces OPNsense (doivent appartenir aux subnets ci-dessus)
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

# --- VPN / On-prem (Fortigate) ---

variable "fortigate_public_ip" {
  type        = string
  description = "IP publique du Fortigate on-prem."
  default     = "195.46.235.220"
}

variable "onprem_address_space" {
  type        = list(string)
  description = "Reseaux LAN derriere le Fortigate."
  default     = ["10.118.255.0/24"]
}

variable "vpn_psk" {
  type        = string
  description = "Cle pre-partagee (PSK) du tunnel IPsec IKEv2."
  sensitive   = true
}

# --- Identifiants VM ---

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

# --- Image Marketplace OPNsense (a verifier, voir README) ---

variable "opnsense_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "Reference de l'image Marketplace OPNsense. A verifier via 'az vm image list'."
  default = {
    publisher = "thefreebsdfoundation"
    offer     = "freebsd-14_2"
    sku       = "14_2-release-amd64-gen2-zfs"
    version   = "latest"
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

# --- Provider OPNsense (config post-deploiement) ---

variable "opnsense_url" {
  type        = string
  description = "URL de l'API OPNsense (ex: https://<ip-mgmt-publique>)."
  default     = ""
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
  type        = bool
  description = "Active la configuration OPNsense via le provider (phase 2)."
  default     = false
}

# Adresse de l'admin autorise a joindre le MGMT (ton IP publique). Laisser vide = ouvert.
variable "mgmt_allowed_source" {
  type    = string
  default = "*"
}
