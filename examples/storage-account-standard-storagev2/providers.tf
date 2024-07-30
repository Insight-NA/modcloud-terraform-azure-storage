terraform {
  required_version = "~>1.3"
  required_providers {
    azurerm = {
      source  = "registry.terraform.io/hashicorp/azurerm"
      version = "~>3.95"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.6.0"
    }
  }

  cloud {}
}

#---------------------------------------------------------------------------------------------
# Azure Configuration
#---------------------------------------------------------------------------------------------

provider "azurerm" {
  features {}
  storage_use_azuread = true
}