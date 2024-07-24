resource "azurerm_private_endpoint" "blob" {
  count = var.enable_private_networking ? 1 : 0

  name                = format("pe-%s-%s", "blob", local.storage_name)
  location            = local.location
  resource_group_name = coalesce(var.pe_resource_group_name, var.resource_group_name)
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = format("pe-%s-%s", "blob", local.storage_name)
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.dns_zone_ids["privatelink.blob.core.windows.net"].id]
  }
}

resource "azurerm_private_endpoint" "table" {
  count = var.enable_private_networking ? 1 : 0

  name                = format("pe-%s-%s", "table", local.storage_name)
  location            = local.location
  resource_group_name = coalesce(var.pe_resource_group_name, var.resource_group_name)
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = format("pe-%s-%s", "table", local.storage_name)
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.dns_zone_ids["privatelink.table.core.windows.net"].id]
  }
}

resource "azurerm_private_endpoint" "queue" {
  count = var.enable_private_networking ? 1 : 0

  name                = format("pe-%s-%s", "queue", local.storage_name)
  location            = local.location
  resource_group_name = coalesce(var.pe_resource_group_name, var.resource_group_name)
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = format("pe-%s-%s", "queue", local.storage_name)
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.dns_zone_ids["privatelink.queue.core.windows.net"].id]
  }
}

resource "azurerm_private_endpoint" "file" {
  count = var.enable_private_networking ? 1 : 0

  name                = format("pe-%s-%s", "file", local.storage_name)
  location            = local.location
  resource_group_name = coalesce(var.pe_resource_group_name, var.resource_group_name)
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = format("pe-%s-%s", "file", local.storage_name)
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.dns_zone_ids["privatelink.file.core.windows.net"].id]
  }
}

resource "azurerm_private_endpoint" "web" {
  count = var.enable_private_networking ? 1 : 0

  name                = format("pe-%s-%s", "web", local.storage_name)
  location            = local.location
  resource_group_name = coalesce(var.pe_resource_group_name, var.resource_group_name)
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = format("pe-%s-%s", "web", local.storage_name)
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["web"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.dns_zone_ids["privatelink.web.core.windows.net"].id]
  }
}

resource "azurerm_private_endpoint" "dfs" {
  count = var.enable_private_networking ? 1 : 0

  name                = format("pe-%s-%s", "dfs", local.storage_name)
  location            = local.location
  resource_group_name = coalesce(var.pe_resource_group_name, var.resource_group_name)
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = format("pe-%s-%s", "dfs", local.storage_name)
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.dns_zone_ids["privatelink.dfs.core.windows.net"].id]
  }
}