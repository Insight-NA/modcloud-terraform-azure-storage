resource "azurerm_storage_table" "this" {
  for_each = { for table in var.storage_table : table.name => table }

  name                 = each.value.name
  storage_account_name = azurerm_storage_account.this.name

  dynamic "acl" {
    for_each = each.value.acl == null ? [] : each.value.acl
    content {
      id = acl.value.id

      dynamic "access_policy" {
        for_each = acl.value.access_policy == null ? [] : acl.value.access_policy
        content {
          # Summary: The start & expiry attributes expect an ISO8061 UTC timestamp. The logic (madness) here enables the module user to enter
          # a date and time for their timezone, and converts that to UTC and in a format that reduces churn, YYYY-MM-DDT00:00:00.0000000Z
          # 
          # Description:
          # The sign is reversed for the user entered UTC offset
          # Check if the user entered the Date format, or the Date and Time format; convert to RFC3339 syntax that the terraform timeadd function expects
          # The reversed UTC offset is added to the formatted timestamp in order to obtain the UTC date and time equivalent
          # The timeadd function returns a RFC3339, and to reduce churn convert to ISO8061 UTC timestamp
          start = replace(
            timeadd(
              length(access_policy.value.start) == 10 ? format("%s%s", access_policy.value.start, "T00:00:00Z") : format("%s%s", access_policy.value.start, "Z"),
              (substr(access_policy.value.utc_offset, 0, 1) == "-" ? replace(access_policy.value.utc_offset, "-", "+") : replace(access_policy.value.utc_offset, "+", "-"))
            ),
            "Z", ".0000000Z"
          )
          expiry = replace(
            timeadd(
              length(access_policy.value.expiry) == 10 ? format("%s%s", access_policy.value.expiry, "T00:00:00Z") : format("%s%s", access_policy.value.expiry, "Z"),
              (substr(access_policy.value.utc_offset, 0, 1) == "-" ? replace(access_policy.value.utc_offset, "-", "+") : replace(access_policy.value.utc_offset, "+", "-"))
            ),
            "Z", ".0000000Z"
          )
          permissions = access_policy.value.permissions
        }
      }
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

  depends_on = [azurerm_storage_container.this, azurerm_storage_queue.this]
}

resource "azurerm_storage_table_entity" "this" {
  for_each = {
    for entity in local.entities : "${entity.table_key}.${entity.entity_key}" => entity
  }

  storage_table_id = azurerm_storage_table.this[each.value.table_name].id
  partition_key    = each.value.partition_key
  row_key          = each.value.row_key
  entity           = each.value.entity

  depends_on = [azurerm_storage_table.this]
}