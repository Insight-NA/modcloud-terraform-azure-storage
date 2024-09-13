terraform {
  required_version = "~>1.3"
  required_providers {
    azurerm = {
      source  = "registry.terraform.io/hashicorp/azurerm"
      version = "~>4.2"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.6.0"
    }
  }
}