resource "azurerm_storage_container" "this" {
  for_each = { for container in var.storage_container : container.name => container }

  name                  = each.value.name
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = each.value.container_access_type
  metadata              = each.value.metadata

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azurerm_storage_blob" "this" {
  for_each = {
    for blob in local.blob : "${blob.container_key}.${blob.blob_key}" => blob
  }

  name                   = each.value.name
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = each.value.container_name
  type                   = each.value.type
  size                   = each.value.size
  access_tier            = each.value.access_tier
  cache_control          = each.value.cache_control
  content_type           = each.value.content_type
  content_md5            = each.value.content_md5
  source                 = each.value.source
  source_content         = each.value.source_content
  source_uri             = each.value.source_uri
  parallelism            = each.value.parallelism
  metadata               = each.value.metadata

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [azurerm_storage_container.this]
}

resource "azurerm_storage_blob_inventory_policy" "this" {
  count = var.blob_inventory_policy == null ? 0 : 1

  storage_account_id = azurerm_storage_account.this.id

  dynamic "rules" {

    for_each = var.blob_inventory_policy == null ? [] : var.blob_inventory_policy

    content {
      name                   = rules.value.name
      storage_container_name = rules.value.storage_container_name
      format                 = rules.value.format
      schedule               = rules.value.schedule
      scope                  = rules.value.scope
      schema_fields          = rules.value.schema_fields

      dynamic "filter" {
        for_each = rules.value.filter == null ? [] : [rules.value.filter]
        content {
          blob_types            = filter.value.blob_types
          include_blob_versions = filter.value.include_blob_versions
          include_deleted       = filter.value.include_deleted
          include_snapshots     = filter.value.include_snapshots
          prefix_match          = filter.value.prefix_match
          exclude_prefixes      = filter.value.exclude_prefixes
        }
      }
    }
  }

  depends_on = [azurerm_storage_container.this]
}