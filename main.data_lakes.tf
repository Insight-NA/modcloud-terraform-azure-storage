resource "azurerm_storage_data_lake_gen2_filesystem" "this" {
  for_each = { for data in var.data_lake_gen2 : data.name => data }

  name               = each.value.name
  storage_account_id = azurerm_storage_account.this.id
  properties         = each.value.properties
  owner              = each.value.owner
  group              = each.value.group

  dynamic "ace" {
    for_each = each.value.ace == null ? [] : [each.value.ace]
    content {
      scope       = ace.value.scope
      type        = ace.value.type
      id          = ace.value.id
      permissions = ace.value.permissions
    }
  }

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [azurerm_storage_account.this]
}

resource "azurerm_storage_data_lake_gen2_path" "this" {
  for_each = {
    for directory in local.directory : "${directory.filesystem_key}.${directory.directory_key}" => directory
  }

  path               = each.value.path
  filesystem_name    = each.value.filesystem_name
  storage_account_id = azurerm_storage_account.this.id
  resource           = "directory"
  owner              = each.value.owner
  group              = each.value.group

  dynamic "ace" {
    for_each = each.value.ace == null ? [] : [each.value.ace]
    content {
      scope       = ace.value.scope
      type        = ace.value.type
      id          = ace.value.id
      permissions = ace.value.permissions
    }
  }

  depends_on = [
    azurerm_storage_account.this,
    azurerm_storage_data_lake_gen2_filesystem.this
  ]
}