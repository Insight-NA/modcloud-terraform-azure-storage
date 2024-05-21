data "azurerm_resource_group" "rgrp" {
  provider = hcaazurerm3
  name     = var.resource_group_name
}

resource "random_id" "random_suffix" {
  byte_length = 8
}

resource "azurerm_storage_account" "this" {
  provider            = hcaazurerm3
  name                = local.storage_name
  resource_group_name = var.resource_group_name != null ? var.resource_group_name : data.azurerm_resource_group.rgrp.name
  location            = var.storage_account_location != null ? var.storage_account_location : data.azurerm_resource_group.rgrp.location

  account_replication_type          = var.account_replication_type
  account_tier                      = var.account_kind == "BlockBlobStorage" || var.account_kind == "FileStorage" ? "Premium" : var.account_tier
  access_tier                       = local.access_tier
  account_kind                      = var.account_kind
  allow_nested_items_to_be_public   = false # This is a hard coded HCA requirement - Sentinel
  allowed_copy_scope                = var.allowed_copy_scope
  cross_tenant_replication_enabled  = false # This is a hard coded HCA requirement - Wiz.io
  default_to_oauth_authentication   = var.default_to_oauth_authentication
  edge_zone                         = var.edge_zone
  enable_https_traffic_only         = true # This is a hard coded HCA requirement - Sentinel
  infrastructure_encryption_enabled = true # This is a hard coded HCA requirement - Sentinel
  is_hns_enabled                    = var.is_hns_enabled
  large_file_share_enabled          = var.large_file_share_enabled
  min_tls_version                   = var.min_tls_version
  nfsv3_enabled                     = var.nfsv3_enabled
  public_network_access_enabled     = var.public_network_access_enabled
  queue_encryption_key_type         = var.queue_encryption_key_type
  sftp_enabled                      = var.sftp_enabled
  shared_access_key_enabled         = var.shared_access_key_enabled
  table_encryption_key_type         = var.table_encryption_key_type
  tags                              = var.tags

  dynamic "azure_files_authentication" {
    for_each = var.azure_files_authentication == null ? [] : [
      var.azure_files_authentication
    ]
    content {
      directory_type = azure_files_authentication.value.directory_type

      dynamic "active_directory" {
        for_each = azure_files_authentication.value.active_directory == null ? [] : [
          azure_files_authentication.value.active_directory
        ]
        content {
          domain_guid         = active_directory.value.domain_guid
          domain_name         = active_directory.value.domain_name
          domain_sid          = active_directory.value.domain_sid
          forest_name         = active_directory.value.forest_name
          netbios_domain_name = active_directory.value.netbios_domain_name
          storage_sid         = active_directory.value.storage_sid
        }
      }
    }
  }
  dynamic "blob_properties" {
    for_each = var.account_kind == "FileStorage" ? [] : (
      var.blob_properties == null ? [local.blob_properties_defaults] : [var.blob_properties]
    )

    content {
      change_feed_enabled           = blob_properties.value.change_feed_enabled
      change_feed_retention_in_days = blob_properties.value.change_feed_retention_in_days
      default_service_version       = blob_properties.value.default_service_version
      last_access_time_enabled      = blob_properties.value.last_access_time_enabled
      versioning_enabled            = var.is_hns_enabled == true ? false : blob_properties.value.versioning_enabled

      container_delete_retention_policy {
        days = (
          blob_properties.value.container_delete_retention_policy == null ? 7 :
          blob_properties.value.container_delete_retention_policy.days == null ? 7 :
          blob_properties.value.container_delete_retention_policy.days < 7 ? 7 :
          blob_properties.value.container_delete_retention_policy.days
        )
      }
      delete_retention_policy {
        days = (
          blob_properties.value.delete_retention_policy == null ? 7 :
          blob_properties.value.delete_retention_policy.days == null ? 7 :
          blob_properties.value.delete_retention_policy.days < 7 ? 7 :
          blob_properties.value.delete_retention_policy.days
        )
      }

      dynamic "cors_rule" {
        for_each = blob_properties.value.cors_rule == null ? [] : blob_properties.value.cors_rule
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "restore_policy" {
        for_each = blob_properties.value.restore_policy == null ? [] : [blob_properties.value.restore_policy]
        content {
          days = restore_policy.value.days
        }
      }
    }
  }
  dynamic "custom_domain" {
    for_each = var.custom_domain == null ? [] : [var.custom_domain]
    content {
      name          = custom_domain.value.name
      use_subdomain = custom_domain.value.use_subdomain
    }
  }
  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = toset(values(identity.value.identity_ids))
    }
  }
  dynamic "immutability_policy" {
    for_each = var.immutability_policy == null ? [] : [var.immutability_policy]
    content {
      allow_protected_append_writes = immutability_policy.value.allow_protected_append_writes
      period_since_creation_in_days = immutability_policy.value.period_since_creation_in_days
      state                         = immutability_policy.value.state
    }
  }
  dynamic "queue_properties" {
    for_each = var.queue_properties == null ? [] : [var.queue_properties]
    content {
      dynamic "cors_rule" {
        for_each = queue_properties.value.cors_rule == null ? [] : queue_properties.value.cors_rule
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }
      dynamic "hour_metrics" {
        for_each = queue_properties.value.hour_metrics == null ? [] : [queue_properties.value.hour_metrics]
        content {
          enabled               = hour_metrics.value.enabled
          version               = hour_metrics.value.version
          include_apis          = hour_metrics.value.include_apis
          retention_policy_days = hour_metrics.value.retention_policy_days
        }
      }
      dynamic "logging" {
        for_each = queue_properties.value.logging == null ? [] : [queue_properties.value.logging]
        content {
          delete                = logging.value.delete
          read                  = logging.value.read
          version               = logging.value.version
          write                 = logging.value.write
          retention_policy_days = logging.value.retention_policy_days
        }
      }
      dynamic "minute_metrics" {
        for_each = queue_properties.value.minute_metrics == null ? [] : [queue_properties.value.minute_metrics]
        content {
          enabled               = minute_metrics.value.enabled
          version               = minute_metrics.value.version
          include_apis          = minute_metrics.value.include_apis
          retention_policy_days = minute_metrics.value.retention_policy_days
        }
      }
    }
  }
  dynamic "routing" {
    for_each = var.routing == null ? [] : [var.routing]
    content {
      choice                      = routing.value.choice
      publish_internet_endpoints  = false # This is a hard coded HCA requirement - Sentinel
      publish_microsoft_endpoints = routing.value.publish_microsoft_endpoints
    }
  }
  dynamic "sas_policy" {
    for_each = var.sas_policy == null ? [] : [var.sas_policy]
    content {
      expiration_period = sas_policy.value.expiration_period
      expiration_action = sas_policy.value.expiration_action
    }
  }
  dynamic "share_properties" {
    for_each = local.share_properties == null ? [] : [local.share_properties]
    content {
      dynamic "cors_rule" {
        for_each = share_properties.value.cors_rule == null ? [] : share_properties.value.cors_rule
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }
      retention_policy {
        days = (
          share_properties.value.retention_policy == null ? 7 :
          share_properties.value.retention_policy.days == null ? 7 :
          share_properties.value.retention_policy.days < 7 ? 7 :
          share_properties.value.retention_policy.days
        )
      }
      dynamic "smb" {
        for_each = share_properties.value.smb == null ? [] : [share_properties.value.smb]
        content {
          authentication_types            = smb.value.authentication_types
          channel_encryption_type         = smb.value.channel_encryption_type
          kerberos_ticket_encryption_type = smb.value.kerberos_ticket_encryption_type
          multichannel_enabled            = smb.value.multichannel_enabled
          versions                        = ["SMB3.1.1"] # This is a hard coded HCA requirement - Wiz.io
        }
      }
    }
  }
  dynamic "static_website" {
    for_each = var.static_website == null ? [] : [var.static_website]
    content {
      error_404_document = static_website.value.error_404_document
      index_document     = static_website.value.index_document
    }
  }
  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    precondition {
      condition = (
        var.account_replication_type == "LRS" && local.app_environment == "prod" ?
        false : true
      )
      error_message = "account_replication_type `LRS` is invalid for prod environments."

    }
  }
}

resource "azurerm_management_lock" "this" {
  provider = hcaazurerm3

  for_each = {
    for key, lock in var.management_locks : key => lock if lock == true
  }

  name       = format("%s%s%s", "lock-", each.key, "-storage-account")
  scope      = azurerm_storage_account.this.id
  lock_level = each.key
  notes      = format("%s%s", "Storage Account level Management Lock - ", each.key)
}

resource "azurerm_storage_blob_inventory_policy" "this" {
  provider = hcaazurerm3

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

resource "azurerm_storage_blob" "this" {
  provider = hcaazurerm3

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

resource "azurerm_storage_account_local_user" "this" {
  provider = hcaazurerm3

  for_each = var.storage_account_local_user

  name                 = each.value.name
  storage_account_id   = azurerm_storage_account.this.id
  home_directory       = each.value.home_directory
  ssh_key_enabled      = each.value.ssh_key_enabled
  ssh_password_enabled = each.value.ssh_password_enabled

  dynamic "permission_scope" {
    for_each = each.value.permission_scope == null ? [] : each.value.permission_scope
    content {
      resource_name = permission_scope.value.resource_name
      service       = permission_scope.value.service

      dynamic "permissions" {
        for_each = [permission_scope.value.permissions]
        content {
          create = permissions.value.create
          delete = permissions.value.delete
          list   = permissions.value.list
          read   = permissions.value.read
          write  = permissions.value.write
        }
      }
    }
  }
  dynamic "ssh_authorized_key" {
    for_each = each.value.ssh_authorized_key == null ? [] : each.value.ssh_authorized_key
    content {
      key         = ssh_authorized_key.value.key
      description = ssh_authorized_key.value.description
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
}

resource "azurerm_storage_account_network_rules" "this" {
  provider                   = hcaazurerm3
  default_action             = "Deny"
  storage_account_id         = azurerm_storage_account.this.id
  bypass                     = var.network_rules.bypass
  ip_rules                   = try(local.allowed_ips, [])
  virtual_network_subnet_ids = try(local.allowed_subnets, [])

  dynamic "private_link_access" {
    for_each = var.network_rules.private_link_access == null ? [] : var.network_rules.private_link_access
    content {
      endpoint_resource_id = private_link_access.value.endpoint_resource_id
      endpoint_tenant_id   = private_link_access.value.endpoint_tenant_id
    }
  }
  dynamic "timeouts" {
    for_each = var.network_rules.timeouts == null ? [] : [var.network_rules.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azurerm_storage_container" "this" {
  provider = hcaazurerm3

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

resource "azurerm_storage_management_policy" "this" {
  provider = hcaazurerm3
  count    = var.management_policy != null ? 1 : 0

  storage_account_id = azurerm_storage_account.this.id

  dynamic "rule" {
    for_each = var.management_policy.rule != null ? var.management_policy.rule : []

    content {
      name    = rule.value.name
      enabled = rule.value.enabled

      filters {
        blob_types   = rule.value.filters.blob_types
        prefix_match = rule.value.filters.prefix_match
        dynamic "match_blob_index_tag" {
          for_each = rule.value.filters.match_blob_index_tag != null ? rule.value.filters.match_blob_index_tag : {}
          content {
            name      = rule.value.filters.match_blob_index_tag.name
            operation = rule.value.filters.match_blob_index_tag.operation
            value     = rule.value.filters.match_blob_index_tag.value
          }
        }
      }

      actions {
        dynamic "base_blob" {
          for_each = rule.value.actions.base_blob != null ? [rule.value.actions.base_blob] : []
          content {
            tier_to_cool_after_days_since_modification_greater_than        = base_blob.value.tier_to_cool_after_days_since_modification_greater_than
            tier_to_cool_after_days_since_last_access_time_greater_than    = base_blob.value.tier_to_cool_after_days_since_last_access_time_greater_than
            tier_to_cool_after_days_since_creation_greater_than            = base_blob.value.tier_to_cool_after_days_since_creation_greater_than
            auto_tier_to_hot_from_cool_enabled                             = base_blob.value.auto_tier_to_hot_from_cool_enabled
            tier_to_archive_after_days_since_modification_greater_than     = base_blob.value.tier_to_archive_after_days_since_modification_greater_than
            tier_to_archive_after_days_since_last_access_time_greater_than = base_blob.value.tier_to_archive_after_days_since_last_access_time_greater_than
            tier_to_archive_after_days_since_creation_greater_than         = base_blob.value.tier_to_archive_after_days_since_creation_greater_than
            tier_to_archive_after_days_since_last_tier_change_greater_than = base_blob.value.tier_to_archive_after_days_since_last_tier_change_greater_than
            delete_after_days_since_modification_greater_than              = base_blob.value.delete_after_days_since_modification_greater_than
            delete_after_days_since_last_access_time_greater_than          = base_blob.value.delete_after_days_since_last_access_time_greater_than
            delete_after_days_since_creation_greater_than                  = base_blob.value.delete_after_days_since_creation_greater_than
          }
        }
        dynamic "snapshot" {
          for_each = rule.value.actions.snapshot != null ? [rule.value.actions.snapshot] : []
          content {
            change_tier_to_archive_after_days_since_creation               = snapshot.value.change_tier_to_archive_after_days_since_creation
            tier_to_archive_after_days_since_last_tier_change_greater_than = snapshot.value.tier_to_archive_after_days_since_last_tier_change_greater_than
            change_tier_to_cool_after_days_since_creation                  = snapshot.value.change_tier_to_cool_after_days_since_creation
            delete_after_days_since_creation_greater_than                  = snapshot.value.delete_after_days_since_creation_greater_than
          }
        }
        dynamic "version" {
          for_each = rule.value.actions.version != null ? [rule.value.actions.version] : []
          content {
            change_tier_to_archive_after_days_since_creation               = version.value.change_tier_to_archive_after_days_since_creation
            tier_to_archive_after_days_since_last_tier_change_greater_than = version.value.tier_to_archive_after_days_since_last_tier_change_greater_than
            change_tier_to_cool_after_days_since_creation                  = version.value.change_tier_to_cool_after_days_since_creation
            delete_after_days_since_creation                               = version.value.delete_after_days_since_creation
          }
        }
      }
    }
  }

  dynamic "timeouts" {
    for_each = var.management_policy.timeouts == null ? [] : [var.management_policy.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azurerm_storage_queue" "this" {
  provider = hcaazurerm3

  for_each = { for queue in var.storage_queue : queue.name => queue }

  name                 = each.value.name
  storage_account_name = azurerm_storage_account.this.name
  metadata             = each.value.metadata

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

resource "azurerm_storage_share" "this" {
  provider = hcaazurerm3

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
  provider = hcaazurerm3

  for_each = {
    for directories in local.directories : "${directories.share_key}.${directories.directories_key}" => directories
  }

  name                 = each.value.directories_name
  share_name           = each.value.share_name
  storage_account_name = azurerm_storage_account.this.name
  metadata             = each.value.metadata

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
  provider = hcaazurerm3

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

resource "azurerm_storage_table" "this" {
  provider = hcaazurerm3

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
  provider = hcaazurerm3

  for_each = {
    for entity in local.entities : "${entity.table_key}.${entity.entity_key}" => entity
  }

  storage_account_name = azurerm_storage_account.this.name
  table_name           = each.value.table_name
  partition_key        = each.value.partition_key
  row_key              = each.value.row_key
  entity               = each.value.entity

  depends_on = [azurerm_storage_table.this]
}

resource "azurerm_storage_data_lake_gen2_filesystem" "this" {
  provider = hcaazurerm3
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
  provider = hcaazurerm3

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