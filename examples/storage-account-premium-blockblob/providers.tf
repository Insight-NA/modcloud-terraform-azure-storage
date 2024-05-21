terraform {
  required_version = ">= 1.3.0"
  required_providers {
    hcaazurerm3 = {
      source  = "app.terraform.io/hca-healthcare/hcaazurerm3"
      version = "~>3.95"
    }
  }

  cloud {}
}

#---------------------------------------------------------------------------------------------
# Azure Configuration
#---------------------------------------------------------------------------------------------

provider "hcaazurerm3" {
  features {}
}