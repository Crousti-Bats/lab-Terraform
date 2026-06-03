terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    opnsense = {
      source  = "browningluke/opnsense"
      version = "~> 0.11"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "opnsense" {
  uri                  = var.opnsense_url
  api_key              = var.opnsense_api_key
  api_secret           = var.opnsense_api_secret
  allow_unverified_tls = true
}
