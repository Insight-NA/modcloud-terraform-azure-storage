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
}