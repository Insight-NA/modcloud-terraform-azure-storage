terraform {
  required_version = ">=1.3"
  required_providers {
    hcaazurerm3 = {
      source  = "app.terraform.io/hca-healthcare/hcaazurerm3"
      version = "~> 3.95"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.6.0"
    }
  }
}