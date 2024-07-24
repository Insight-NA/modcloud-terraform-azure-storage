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
  
  private_dns_zones = toset([
    "privatelink.blob.core.windows.net",
    "privatelink.table.core.windows.net",
    "privatelink.queue.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.web.core.windows.net",
    "privatelink.dfs.core.windows.net"
  ])

  private_dns_zone_map = {
    for zone_name, zone in azurerm_private_dns_zone.this : zone_name => {
      name = zone.name
      id   = zone.id
    }
  }
}

data "azurerm_subnet" "test_sub" {
  name                 = "default"
  virtual_network_name = "module-testing-vnet"
  resource_group_name  = var.resource_group_name
}

resource "random_id" "random_suffix" {
  byte_length = 8
}

resource "azurerm_private_dns_zone" "this" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = var.resource_group_name
}

module "azure_storage_account_network_rules" {
  source               = "../../"
  tags                 = local.tags
  storage_account_name = substr(format("st%s%s%s%s", local.tags.app_code, local.tags.env, local.tags.app_instance, random_id.random_suffix.hex), 0, 24)
  resource_group_name  = var.resource_group_name

  enable_private_networking  = true
  private_endpoint_subnet_id = data.azurerm_subnet.test_sub.id
  dns_zone_ids               = local.private_dns_zone_map

  network_rules = {
    # This could be a specific ip address for individual users, e.g., 20.94.5.238
    # or an ip range for a group of users (VPN), e.g., 20.128.0.0/16
    ip_rules                   = ["20.94.5.238"]
    virtual_network_subnet_ids = [data.azurerm_subnet.test_sub.id]
  }
}