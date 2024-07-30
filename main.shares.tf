resource "azurerm_storage_share" "this" {
  for_each = { for share in var.storage_share : share.name => share }

  name                 = each.value.name
  quota                = each.value.quota
  storage_account_name = azurerm_storage_account.this.name
  access_tier          = each.value.access_tier
  enabled_protocol     = each.value.enabled_protocol
  metadata             = each.value.metadata

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

  lifecycle {
    precondition {
      condition     = alltrue([for share in var.storage_share : share.enabled_protocol == "NFS" ? false : true])
      error_message = "Fileshares of the 'NFS' protocol are not supported at this time. The NFS protocol does not support encryption and relies on network-level security, however HCA policy requires enable_https_traffic_only be set to true."
    }
  }
}

resource "azurerm_storage_share_directory" "this" {
  for_each = {
    for directories in local.directories : "${directories.share_key}.${directories.directories_key}" => directories
  }

  name             = each.value.directories_name
  storage_share_id = azurerm_storage_share.this[each.value.share_name].id
  # TODO Delete
  #share_name           = each.value.share_name
  #storage_account_name = azurerm_storage_account.this.name
  metadata = each.value.metadata

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [azurerm_storage_share.this]
}

resource "azurerm_storage_share_file" "this" {
  for_each = {
    for files in local.files : "${files.share_key}.${files.directories_key}.${files.files_key}" => files
  }

  name                = each.value.name
  storage_share_id    = each.value.storage_share_id
  path                = each.value.path
  source              = each.value.source
  content_type        = each.value.content_type
  content_md5         = each.value.content_md5
  content_encoding    = each.value.content_encoding
  content_disposition = each.value.content_disposition
  metadata            = each.value.metadata

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }


  depends_on = [azurerm_storage_share.this, azurerm_storage_share_directory.this]
}