variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  type        = string
  default     = "terraform-module-testing"
}

variable "virtual_network_name" {
  description = "Virtual Network"
  type        = string
  default     = "module-testing-vnet"
}