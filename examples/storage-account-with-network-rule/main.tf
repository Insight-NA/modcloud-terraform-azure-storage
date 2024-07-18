locals {
  tags = {
    env            = "prod"
    app_code       = "tst"
    app_instance   = "tbd"
    classification = "internal-only"
    cost_id        = "12345"
    department_id  = "678901"
    project_id     = "it-ab00c123"
  }
}

data "azurerm_subnet" "test_sub" {
  name                 = "default"
  virtual_network_name = "module-testing-vnet"
  resource_group_name  = var.resource_group_name
}

module "azure_storage_account_network_rules" {
  source              = "../../"
  tags                = local.tags
  resource_group_name = var.resource_group_name
  network_rules = {
    ip_rules                   = ["127.0.0.1", "127.0.113.0/24"]
    virtual_network_subnet_ids = [data.azurerm_subnet.test_sub.id]
  }
}