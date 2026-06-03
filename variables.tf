variable "subscription_id" {
  description = "Azure subscription ID (az account show --query id -o tsv)"
  type        = string
}

variable "prefix" {
  description = "Prefix used for resource naming"
  type        = string
  default     = "lab"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "France Central"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    project = "lab-terraform"
    env     = "lab"
  }
}

# --- Palo Alto (firewall VM) ---
variable "palo_alto_admin_username" {
  description = "Admin username for the Palo Alto VM"
  type        = string
  default     = "paadmin"
}

variable "palo_alto_admin_password" {
  description = "Admin password for the Palo Alto VM"
  type        = string
  sensitive   = true
}

variable "palo_alto_vm_size" {
  description = "VM size (must support 3 NICs)"
  type        = string
  default     = "Standard_D3_v2"
}

variable "palo_alto_sku" {
  description = "Palo Alto vmseries-flex SKU (byol, bundle1, bundle2)"
  type        = string
  default     = "byol"
}

variable "accept_marketplace_agreement" {
  description = "Accept the Palo Alto marketplace plan terms (set false if already accepted on the subscription)"
  type        = bool
  default     = true
}

# --- Ubuntu spoke VM ---
variable "linux_admin_username" {
  description = "Admin username for the Ubuntu VM"
  type        = string
  default     = "azureuser"
}

variable "linux_admin_password" {
  description = "Admin password for the Ubuntu VM"
  type        = string
  sensitive   = true
}

variable "allowed_ssh_source" {
  description = "Source IP/CIDR allowed to SSH the Ubuntu VM (restrict this!)"
  type        = string
  default     = "*"
}

# --- On-premise (Fortigate) ---
variable "onprem_gateway_address" {
  description = "Public IP of the on-premise Fortigate"
  type        = string
  default     = "195.46.235.220"
}

variable "onprem_address_space" {
  description = "On-premise private network(s)"
  type        = list(string)
  default     = ["10.118.255.0/24"]
}

variable "vpn_shared_key" {
  description = "IPsec pre-shared key (PSK) for the site-to-site tunnel"
  type        = string
  sensitive   = true
}
