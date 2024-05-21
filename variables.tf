variable "account_kind" {
  type        = string
  default     = "StorageV2"
  description = "(Optional) Defines the Kind of account. Valid options are `BlobStorage`, `BlockBlobStorage`, `FileStorage`, `Storage` and `StorageV2`. Defaults to `StorageV2`."

  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "Valid values for var.account_kind are (BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2)."
  }
}

variable "account_replication_type" {
  type        = string
  default     = "RAGRS"
  description = "(Required) Defines the type of replication to use for this storage account. Valid options are `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS` and `RAGZRS`."
  nullable    = false

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Valid values for var.account_replication_type are `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS` and `RAGZRS`."
  }
}

variable "access_tier" {
  type        = string
  default     = "Hot"
  description = "(Optional) Defines the access tier for `BlobStorage`, `FileStorage` and `StorageV2` accounts. Valid options are `Hot` and `Cool`, defaults to `Hot`."
}

variable "account_tier" {
  type        = string
  default     = "Standard"
  description = "(Required) Defines the Tier to use for this storage account. Valid options are `Standard` and `Premium`. For `BlockBlobStorage` and `FileStorage` accounts only `Premium` is valid. Changing this forces a new resource to be created."
  nullable    = false

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Valid values for var.account_tier are `Standard` and `Premium`."
  }
}

variable "allowed_copy_scope" {
  type        = string
  default     = null
  description = "(Optional) Restrict copy to and from Storage Accounts within an AAD tenant or with Private Links to the same VNet. Possible values are `AAD` and `PrivateLink`."
}

variable "azure_files_authentication" {
  type = object({
    directory_type = string
    active_directory = optional(object({
      domain_guid         = string
      domain_name         = string
      domain_sid          = string
      forest_name         = string
      netbios_domain_name = string
      storage_sid         = string
    }))
  })
  default     = null
  description = <<-EOT
 - `directory_type` - (Required) Specifies the directory service used. Possible values are `AADDS`, `AD` and `AADKERB`.

 ---
 `active_directory` block supports the following:
 - `domain_guid` - (Required) Specifies the domain GUID.
 - `domain_name` - (Required) Specifies the primary domain that the AD DNS server is authoritative for.
 - `domain_sid` - (Required) Specifies the security identifier (SID).
 - `forest_name` - (Required) Specifies the Active Directory forest.
 - `netbios_domain_name` - (Required) Specifies the NetBIOS domain name.
 - `storage_sid` - (Required) Specifies the security identifier (SID) for Azure Storage.
EOT
}

variable "blob_properties" {
  type = object({
    change_feed_enabled           = optional(bool)
    change_feed_retention_in_days = optional(number)
    default_service_version       = optional(string)
    last_access_time_enabled      = optional(bool)
    versioning_enabled            = optional(bool, true)
    container_delete_retention_policy = optional(object({
      days = optional(number)
    }))
    cors_rule = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })))
    delete_retention_policy = optional(object({
      days = optional(number)
    }))
    restore_policy = optional(object({
      days = number
    }))
  })
  default     = null
  description = <<-EOT
 - `change_feed_enabled` - (Optional) Is the blob service properties for change feed events enabled? Default to `false`.
 - `change_feed_retention_in_days` - (Optional) The duration of change feed events retention in days. The possible values are between 1 and 146000 days (400 years). Setting this to null (or omit this in the configuration file) indicates an infinite retention of the change feed.
 - `default_service_version` - (Optional) The API Version which should be used by default for requests to the Data Plane API if an incoming request doesn't specify an API Version.
 - `last_access_time_enabled` - (Optional) Is the last access time based tracking enabled? Default to `false`.
 - `versioning_enabled` - (Optional) Is versioning enabled? Default to `false`.

 ---
 `container_delete_retention_policy` block supports the following:
 - `days` - (Optional) Specifies the number of days that the container should be retained, between `1` and `365` days. Defaults to `7`.

 ---
 `cors_rule` block supports the following:
 - `allowed_headers` - (Required) A list of headers that are allowed to be a part of the cross-origin request.
 - `allowed_methods` - (Required) A list of HTTP methods that are allowed to be executed by the origin. Valid options are `DELETE`, `GET`, `HEAD`, `MERGE`, `POST`, `OPTIONS`, `PUT` or `PATCH`.
 - `allowed_origins` - (Required) A list of origin domains that will be allowed by CORS.
 - `exposed_headers` - (Required) A list of response headers that are exposed to CORS clients.
 - `max_age_in_seconds` - (Required) The number of seconds the client should cache a preflight response.

 ---
 `delete_retention_policy` block supports the following:
 - `days` - (Optional) Specifies the number of days that the blob should be retained, between `1` and `365` days. Defaults to `7`.

 ---
 `restore_policy` block supports the following:
 - `days` - (Required) Specifies the number of days that the blob can be restored, between `1` and `365` days. This must be less than the `days` specified for `delete_retention_policy`.
EOT
  validation {
    condition = var.blob_properties == null ? true : (
      var.blob_properties.container_delete_retention_policy == null ? true :
    var.blob_properties.container_delete_retention_policy.days >= 7)
    error_message = "The Blob Properties Container Delete Retention Policy must be 7 days or greater."
  }
  validation {
    condition = var.blob_properties == null ? true : (
      var.blob_properties.delete_retention_policy == null ? true :
    var.blob_properties.delete_retention_policy.days >= 7)
    error_message = "The Blob Properties (Blob) Delete Retention Policy must be 7 days or greater."
  }
}

variable "blob_inventory_policy" {
  type = list(object({
    name                   = string
    storage_container_name = string
    format                 = string
    schedule               = string
    scope                  = string
    schema_fields          = list(string)
    filter = optional(object({
      blob_types            = set(string)
      include_blob_versions = optional(bool, false)
      include_deleted       = optional(bool, false)
      include_snapshots     = optional(bool, false)
      prefix_match          = optional(set(string))
      exclude_prefixes      = optional(set(string))
    }))
  }))
  default     = null
  description = <<-EOT
- `name` - (Required) The name which should be used for this Blob Inventory Policy Rule.
- `storage_container_name` - (Required) The storage container name to store the blob inventory files for this rule.
- `format` - (Required) The format of the inventory files. Possible values are `Csv` and `Parquet`.
- `schedule` - (Required) The inventory schedule applied by this rule. Possible values are `Daily` and `Weekly`.
- `scope` - (Required) The scope of the inventory for this rule. Possible values are `Blob` and `Container`.
- `schema_fields` - (Required) A list of fields to be included in the inventory. See the Azure API reference Blob Inventory Policies for all the supported fields.
- `filter` block
- `timeouts` block

---
`filter` block supports the following:
- `blob_types ` - (Required) A set of blob types. Possible values are `blockBlob`, `appendBlob`, and `pageBlob`. The storage account with `is_hns_enabled` is true doesn't support `pageBlob`.
- `include_blob_versions` - (Optional) Includes blob versions in blob inventory or not? Defaults to `false`.
- `include_deleted` - (Optional) Includes deleted blobs in blob inventory or not? Defaults to `false`.
- `include_snapshots` - (Optional) Includes blob snapshots in blob inventory or not? Defaults to `false`.
- `prefix_match` - (Optional) A set of strings for blob prefixes to be matched. Maximum of 10 blob prefixes.
- `exclude_prefixes` - (Optional) A set of strings for blob prefixes to be excluded. Maximum of 10 blob prefixes.
EOT
  nullable    = true
}

variable "custom_domain" {
  type = object({
    name          = string
    use_subdomain = optional(bool)
  })
  default     = null
  description = <<-EOT
 - `name` - (Required) The Custom Domain Name to use for the Storage Account, which will be validated by Azure.
 - `use_subdomain` - (Optional) Should the Custom Domain Name be validated by using indirect CNAME validation?
EOT
}

variable "data_lake_gen2" {
  type = list(object({
    name       = string
    properties = optional(map(string))
    ace = optional(list(object({
      scope       = optional(string)
      type        = string
      id          = optional(string)
      permissions = string
    })))
    owner = optional(string)
    group = optional(string)
    directory = optional(list(object({
      path  = string
      owner = optional(string)
      group = optional(string)
      ace = optional(list(object({
        scope       = optional(string)
        type        = string
        id          = optional(string)
        permissions = string
      })))
    })))
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }))
  }))
  default     = []
  description = <<-EOT
- `name` - (Required) The name of the Data Lake Gen2 File System which should be created within the Storage Account. Must be unique within the storage account the queue is located. Changing this forces a new resource to be created.
- `properties` - (Optional) A mapping of Key to Base64-Encoded Values which should be assigned to this Data Lake Gen2 File System.
- `ace` - (Optional) One or more ace blocks as defined below to specify the entries for the ACL for the path.
- `owner` - (Optional) Specifies the Object ID of the Azure Active Directory User to make the owning user of the root path (i.e. /). Possible values also include $superuser.
- `group` - (Optional) Specifies the Object ID of the Azure Active Directory Group to make the owning group of the root path (i.e. /). Possible values also include $superuser.

---
An `ace` block supports the following:
- `scope` - (Optional) Specifies whether the ACE represents an access entry or a default entry. Default value is access.
- `type` - (Required) Specifies the type of entry. Can be user, group, mask or other.
- `id` - (Optional) Specifies the Object ID of the Azure Active Directory User or Group that the entry relates to. Only valid for user or group entries.
- `permissions` - (Required) Specifies the permissions for the entry in rwx form. For example, rwx gives full permissions but r-- only gives read permissions.
More details on ACLs can be found here: https://docs.microsoft.com/azure/storage/blobs/data-lake-storage-access-control#access-control-lists-on-files-and-directories

---
An `path` block supports the following:
- `path` - (Required) The path which should be created within the Data Lake Gen2 File System in the Storage Account. Changing this forces a new resource to be created.
- `resource` - (Required) Specifies the type for path to create. Currently only directory is supported. Changing this forces a new resource to be created.
- `owner` - (Optional) Specifies the Object ID of the Azure Active Directory User to make the owning user. Possible values also include $superuser.
- `group` - (Optional) Specifies the Object ID of the Azure Active Directory Group to make the owning group. Possible values also include $superuser.
- `ace` - (Optional) One or more ace blocks as defined below to specify the entries for the ACL for the path.

---
The `timeouts` block supports the following:
- `create` - (Defaults to 30 minutes) Used when creating the Data Lake Gen2 File System.
- `update` - (Defaults to 30 minutes) Used when updating the Data Lake Gen2 File System.
- `read` - (Defaults to 5 minutes) Used when retrieving the Data Lake Gen2 File System.
- `delete` - (Defaults to 30 minutes) Used when deleting the Data Lake Gen2 File System.
  EOT
}

variable "default_to_oauth_authentication" {
  type        = bool
  default     = false
  description = "(Optional) Default to Azure Active Directory authorization in the Azure portal when accessing the Storage Account. The default value is `false`"
}

variable "edge_zone" {
  type        = string
  default     = null
  description = "(Optional) Specifies the Edge Zone within the Azure Region where this Storage Account should exist. Changing this forces a new Storage Account to be created."
}

variable "identity" {
  type = object({
    identity_ids = optional(map(string))
    type         = string
  })
  default     = null
  description = <<-EOT
 - `identity_ids` - (Optional) Specifies a list of User Assigned Managed Identity IDs to be assigned to this Storage Account.
 - `type` - (Required) Specifies the type of Managed Service Identity that should be configured on this Storage Account. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned` (to enable both).
EOT
}

variable "immutability_policy" {
  type = object({
    allow_protected_append_writes = bool
    period_since_creation_in_days = number
    state                         = string
  })
  default     = null
  description = <<-EOT
 - `allow_protected_append_writes` - (Required) When enabled, new blocks can be written to an append blob while maintaining immutability protection and compliance. Only new blocks can be added and any existing blocks cannot be modified or deleted.
 - `period_since_creation_in_days` - (Required) The immutability period for the blobs in the container since the policy creation, in days.
 - `state` - (Required) Defines the mode of the policy. `Disabled` state disables the policy, `Unlocked` state allows increase and decrease of immutability retention time and also allows toggling allowProtectedAppendWrites property, `Locked` state only allows the increase of the immutability retention time. A policy can only be created in a Disabled or Unlocked state and can be toggled between the two states. Only a policy in an Unlocked state can transition to a Locked state which cannot be reverted.
EOT
}

variable "is_hns_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Is Hierarchical Namespace enabled? This can be used with Azure Data Lake Storage Gen 2 ([see here for more information](https://docs.microsoft.com/azure/storage/blobs/data-lake-storage-quickstart-create-account/)). Changing this forces a new resource to be created."
}

variable "large_file_share_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Is Large File Share Enabled?"
}

variable "management_locks" {
  type = object({
    CanNotDelete = bool
    ReadOnly     = optional(bool)
  })
  default = {
    CanNotDelete = true
    ReadOnly     = false
  }
  description = <<-EOT
  A map of management locks
  - `CanNotDelete` - (Required) Storage Account level CanNotDelete Management Lock. Authorized users are able to read and modify the resources, but not delete. Defaults to `true`. Changing this forces a new resource to be created.
  - `ReadyOnly` - (Optional) Storage Account level ReadOnly Management Lock. Authorized users can only read from a resource, but they can't modify or delete. Defaults to `false`. Changing this forces a new resource to be created.
EOT
  nullable    = false
}

variable "management_policy" {
  type = object({
    rule = optional(list(object({
      name    = string
      enabled = bool
      filters = object({
        blob_types   = list(string)
        prefix_match = optional(list(string))
        match_blob_index_tag = optional(object({
          name      = string
          operation = optional(string, "==")
          value     = string
        }))
      })
      actions = object({
        base_blob = optional(object({
          tier_to_cool_after_days_since_modification_greater_than        = optional(number)
          tier_to_cool_after_days_since_last_access_time_greater_than    = optional(number)
          tier_to_cool_after_days_since_creation_greater_than            = optional(number)
          auto_tier_to_hot_from_cool_enabled                             = optional(bool)
          tier_to_archive_after_days_since_modification_greater_than     = optional(number)
          tier_to_archive_after_days_since_last_access_time_greater_than = optional(number)
          tier_to_archive_after_days_since_creation_greater_than         = optional(number)
          tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
          delete_after_days_since_modification_greater_than              = optional(number)
          delete_after_days_since_last_access_time_greater_than          = optional(number)
          delete_after_days_since_creation_greater_than                  = optional(number)
        }))
        snapshot = optional(object({
          change_tier_to_archive_after_days_since_creation               = optional(number)
          tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
          change_tier_to_cool_after_days_since_creation                  = optional(number)
          delete_after_days_since_creation_greater_than                  = optional(number)
        }))
        version = optional(object({
          change_tier_to_archive_after_days_since_creation               = optional(number)
          tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
          change_tier_to_cool_after_days_since_creation                  = optional(number)
          delete_after_days_since_creation                               = optional(number)
        }))
      })
    })))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
  default     = null
  description = <<-EOT
 `rule` block supports the following:
 - `name` - (Required) The name of the rule. Rule name is case-sensitive. It must be unique within a policy.
 - `enabled` - (Required) Boolean to specify whether the rule is enabled.
 - `filters` - (Required) A filters block as documented below.
 - `actions` - (Required) An actions block as documented below.

 ---
 `filters` block supports the following:
 - `blob_types` - (Required) An array of predefined values. Valid options are `blockBlob` and `appendBlob`.
 - `prefix_match` - (Optional) An array of strings for prefixes to be matched.
 - `match_blob_index_tag` - (Optional) A match_blob_index_tag object as defined below. The object defines the blob index tag based filtering for blob objects.
 Note: The `match_blob_index_tag` block cannot be set if the snapshot and/or version blocks are set.

---
`match_blob_index_tag` block supports the following
- `name` - (Required) The filter tag name used for tag based filtering for blob objects.
- `operation` - (Optional) The comparison operator which is used for object comparison and filtering. Possible value is ==. Defaults to ==.
- `value` - (Required) The filter tag value used for tag based filtering for blob objects.

 ---
 `actions` block supports the following:
 - `base_blob` - (Optional) A base_blob block as documented below.
 - `snapshot` - (Optional) A snapshot block as documented below.
 - `version` - (Optional) A version block as documented below.

 ---
 `base_blob` block supports the following:
 - `tier_to_cool_after_days_since_modification_greater_than` - (Optional) The age in days after last modification to tier blobs to cool storage. Supports blob currently at Hot tier. Must be between 0 and 99999. Defaults to -1.
 - `tier_to_cool_after_days_since_last_access_time_greater_than` - (Optional) The age in days after last access time to tier blobs to cool storage. Supports blob currently at Hot tier. Must be between 0 and 99999. Defaults to -1.
 - `tier_to_cool_after_days_since_creation_greater_than` - (Optional) The age in days after creation to cool storage. Supports blob currently at Hot tier. Must be between 0 and 99999. Defaults to -1.
 Note: The `tier_to_cool_after_days_since_modification_greater_than`, `tier_to_cool_after_days_since_last_access_time_greater_than`, and `tier_to_cool_after_days_since_creation_greater_than` can not be set at the same time.

 - `auto_tier_to_hot_from_cool_enabled` - (Optional) Whether a blob should automatically be tiered from cool back to hot if it's accessed again after being tiered to cool. Defaults to false.
 Note: The `auto_tier_to_hot_from_cool_enabled` must be used together with `tier_to_cool_after_days_since_last_access_time_greater_than`.

 - `tier_to_archive_after_days_since_modification_greater_than` - (Optional) The age in days after last modification to tier blobs to archive storage. Supports blob currently at Hot or Cool tier. Must be between 0 and 99999. Defaults to -1.
 - `tier_to_archive_after_days_since_last_access_time_greater_than` - (Optional) The age in days after last access time to tier blobs to archive storage. Supports blob currently at Hot or Cool tier. Must be between 0 and 99999. Defaults to -1.
 Note: The `tier_to_archive_after_days_since_modification_greater_than`, `tier_to_archive_after_days_since_last_access_time_greater_than`, and `tier_to_archive_after_days_since_creation_greater_than` can not be set at the same time.

 - `tier_to_archive_after_days_since_last_tier_change_greater_than` - (Optional) The age in days after last tier change to the blobs to skip to be archived. Must be between 0 and 99999. Defaults to -1.
 Note: The `tier_to_cool_after_days_since_modification_greater_than`, `tier_to_cool_after_days_since_last_access_time_greater_than`, and `tier_to_cool_after_days_since_creation_greater_than` can not be set at the same time.

 - `delete_after_days_since_modification_greater_than` - (Optional) The age in days after last modification to delete the blob. Must be between 0 and 99999. Defaults to -1.
 - `delete_after_days_since_last_access_time_greater_than` - (Optional) The age in days after last access time to delete the blob. Must be between 0 and 99999. Defaults to -1.
 - `delete_after_days_since_creation_greater_than` - (Optional) The age in days after creation to delete the blob. Must be between 0 and 99999. Defaults to -1.
 Note: The `delete_after_days_since_modification_greater_than`, `delete_after_days_since_last_access_time_greater_than`, and `delete_after_days_since_creation_greater_than` can not be set at the same time.
 Note: The `last_access_time_enabled` must be set to true in the `azurerm_storage_account` in order to use `tier_to_cool_after_days_since_last_access_time_greater_than`, `tier_to_archive_after_days_since_last_access_time_greater_than`, and `delete_after_days_since_last_access_time_greater_than`.

 ---
 `snapshot` block supports the following:
 - `change_tier_to_archive_after_days_since_creation` - (Optional) The age in days after creation to tier blob snapshot to archive storage. Must be between 0 and 99999. Defaults to -1.
 - `tier_to_archive_after_days_since_last_tier_change_greater_than` - (Optional) The age in days after last tier change to the blobs to skip to be archived. Must be between 0 and 99999. Defaults to -1.
 - `change_tier_to_cool_after_days_since_creation` - (Optional) The age in days after creation to tier blob snapshot to cool storage. Must be between 0 and 99999. Defaults to -1.
 - `delete_after_days_since_creation`- (Optional) The age in days after creation to delete the blob version. Must be between 0 and 99999. Defaults to -1.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 60 minutes) Used when creating the  Network Rules for this Storage Account.
 - `delete` - (Defaults to 60 minutes) Used when deleting the Network Rules for this Storage Account.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Network Rules for this Storage Account.
 - `update` - (Defaults to 60 minutes) Used when updating the Network Rules for this Storage Account.
EOT
  nullable    = true
}

variable "min_tls_version" {
  type        = string
  default     = "TLS1_2"
  description = "(Optional) The minimum supported TLS version for the storage account. Defaults to `TLS1_2` for new storage accounts."

  validation {
    condition     = !contains(["tls1_0", "TLS1_0", "tls1_1", "TLS1_1"], var.min_tls_version)
    error_message = "TLS versions earlier than 1.2 are not permitted"
  }
}

variable "network_rules" {
  type = object({
    hca_ips_enabled            = optional(bool, false)
    bypass                     = optional(set(string), ["Logging", "Metrics", "AzureServices"])
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(set(string))
    private_link_access = optional(list(object({
      endpoint_resource_id = string
      endpoint_tenant_id   = optional(string)
    })))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
  default     = {}
  description = <<-EOT
 - `hca_ip_enabled` - (Optional) Enables HCA Terraform Cloud <region 1> US and <region 2> US networks access to deployed resources. Setting to `false` is NOT recommend, but there may be specific use cases. Defaults to `true`.
 - `bypass` - (Optional) Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Valid options are any combination of `Logging`, `Metrics`, `AzureServices`, or `None`.
 - `ip_rules` - (Optional) List of public IP or IP ranges in CIDR Format. Only IPv4 addresses are allowed. Private IP address ranges (as defined in [RFC 1918](https://tools.ietf.org/html/rfc1918#section-3)) are not allowed.
 - `storage_account_id` - (Required) Specifies the ID of the storage account. Changing this forces a new resource to be created.
 - `virtual_network_subnet_ids` - (Optional) A list of virtual network subnet ids to secure the storage account.
 - `subnet_id` - (Required) The ID of the Subnet from which Private IP Addresses will be allocated for this Private Endpoint. Changing this forces a new resource to be created.

 ---
 `private_link_access` block supports the following:
 - `endpoint_resource_id` - (Required) The resource id of the resource access rule to be granted access.
 - `endpoint_tenant_id` - (Optional) The tenant id of the resource of the resource access rule to be granted access. Defaults to the current tenant id.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 60 minutes) Used when creating the  Network Rules for this Storage Account.
 - `delete` - (Defaults to 60 minutes) Used when deleting the Network Rules for this Storage Account.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Network Rules for this Storage Account.
 - `update` - (Defaults to 60 minutes) Used when updating the Network Rules for this Storage Account.
EOT
  nullable    = false
}

variable "nfsv3_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Is NFSv3 protocol enabled? Changing this forces a new resource to be created. Defaults to `false`."
}

variable "private_dns_zones_for_private_link" {
  type = map(object({
    resource_group_name       = string
    name                      = string
    virtual_network_link_name = string
  }))
  default     = {}
  description = <<-EOT
  A map of private dns zones that used to create corresponding a records and cname records for the private endpoints, the key is static string for the storage service, like `blob`, `table`, `queue`.
  - `resource_group_name` - (Required) Specifies the resource group where the resource exists. Changing this forces a new resource to be created.
  - `name` - (Required) The name of the Private DNS Zone for private link endpoint. Must be a valid domain name, e.g.: `privatelink.blob.core.windows.net`. Changing this forces a new resource to be created.
  - `virtual_network_link_name` - (Required) The name of the Private DNS Zone Virtual Network Link.
EOT
  nullable    = false

  validation {
    condition = alltrue([
      for n, z in var.private_dns_zones_for_private_link : contains(["blob", "table", "queue", "share"], n)
    ])
    error_message = "The map's key must be one of `blob`, `table`, `queue`, `share`."
  }
}

variable "private_dns_zones_for_public_endpoint" {
  type = map(object({
    resource_group_name       = string
    name                      = string
    virtual_network_link_name = string
  }))
  default     = {}
  description = <<-EOT
  A map of private dns zones that used to create corresponding a records and cname records for the public endpoints, the key is static string for the storage service, like `blob`, `table`, `queue`.
  - `resource_group_name` - (Required) Specifies the resource group where the resource exists. Changing this forces a new resource to be created.
  - `name` - (Required) The name of the Private DNS Zone for private link endpoint. Must be a valid domain name, e.g.: `blob.core.windows.net`. Changing this forces a new resource to be created.
  - `virtual_network_link_name` - (Required) The name of the Private DNS Zone Virtual Network Link.
EOT
  nullable    = false

  validation {
    condition = alltrue([
      for n, z in var.private_dns_zones_for_public_endpoint : contains(["table", "queue"], n)
    ])
    error_message = "The map's key must be one of `table`, `queue`."
  }
}

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Whether the public network access is enabled? Defaults to `true`."
}

variable "queue_encryption_key_type" {
  type        = string
  default     = "Service"
  description = "(Optional) The encryption type of the queue service. Possible values are `Service` and `Account`. Changing this forces a new resource to be created. Default value is `Service`."
}

variable "queue_properties" {
  type = object({
    cors_rule = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })))
    hour_metrics = optional(object({
      enabled               = bool
      include_apis          = optional(bool)
      retention_policy_days = optional(number)
      version               = string
    }))
    logging = optional(object({
      delete                = bool
      read                  = bool
      retention_policy_days = number
      version               = string
      write                 = bool
    }))
    minute_metrics = optional(object({
      enabled               = bool
      include_apis          = optional(bool)
      retention_policy_days = number
      version               = string
    }))
  })
  default     = null
  description = <<-EOT

 ---
 `cors_rule` block supports the following:
 - `allowed_headers` - (Required) A list of headers that are allowed to be a part of the cross-origin request.
 - `allowed_methods` - (Required) A list of HTTP methods that are allowed to be executed by the origin. Valid options are `DELETE`, `GET`, `HEAD`, `MERGE`, `POST`, `OPTIONS`, `PUT` or `PATCH`.
 - `allowed_origins` - (Required) A list of origin domains that will be allowed by CORS.
 - `exposed_headers` - (Required) A list of response headers that are exposed to CORS clients.
 - `max_age_in_seconds` - (Required) The number of seconds the client should cache a preflight response.

 ---
 `hour_metrics` block supports the following:
 - `enabled` - (Required) Indicates whether hour metrics are enabled for the Queue service.
 - `include_apis` - (Optional) Indicates whether metrics should generate summary statistics for called API operations.
 - `retention_policy_days` - (Optional) Specifies the number of days that logs will be retained.
 - `version` - (Required) The version of storage analytics to configure.

 ---
 `logging` block supports the following:
 - `delete` - (Required) Indicates whether all delete requests should be logged.
 - `read` - (Required) Indicates whether all read requests should be logged.
 - `retention_policy_days` - (Optional) Specifies the number of days that logs will be retained.
 - `version` - (Required) The version of storage analytics to configure.
 - `write` - (Required) Indicates whether all write requests should be logged.

 ---
 `minute_metrics` block supports the following:
 - `enabled` - (Required) Indicates whether minute metrics are enabled for the Queue service.
 - `include_apis` - (Optional) Indicates whether metrics should generate summary statistics for called API operations.
 - `retention_policy_days` - (Optional) Specifies the number of days that logs will be retained.
 - `version` - (Required) The version of storage analytics to configure.
EOT

  validation {
    condition = alltrue([
      try(var.queue_properties.minute_metrics.retention_policy_days >= 1, true)
    ])
    error_message = "Queue minute metric retention policy days must be greater than 0."
  }
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which to create the storage account. Changing this forces a new resource to be created."
  nullable    = false
}

variable "routing" {
  type = object({
    choice                      = optional(string)
    publish_microsoft_endpoints = optional(bool)
  })
  default     = null
  description = <<-EOT
 - `choice` - (Optional) Specifies the kind of network routing opted by the user. Possible values are `InternetRouting` and `MicrosoftRouting`. Defaults to `MicrosoftRouting`.
 - `publish_microsoft_endpoints` - (Optional) Should Microsoft routing storage endpoints be published? Defaults to `false`.
EOT
}

variable "sas_policy" {
  type = object({
    expiration_action = optional(string, "Log")
    expiration_period = string
  })
  default = {
    expiration_period = "00.01:00:00"
  }
  description = <<-EOT
 - `expiration_action` - (Optional) The SAS expiration action. The only possible value is `Log` at this moment. Defaults to `Log`.
 - `expiration_period` - (Required) The SAS expiration period in format of `DD.HH:MM:SS`.
EOT
}

variable "sftp_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Boolean, enable SFTP for the storage account"
}

variable "share_properties" {
  type = object({
    cors_rule = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })))
    retention_policy = optional(object({
      days = optional(number)
    }))
    smb = optional(object({
      authentication_types            = optional(set(string))
      channel_encryption_type         = optional(set(string))
      kerberos_ticket_encryption_type = optional(set(string))
      multichannel_enabled            = optional(bool)
    }))
  })
  default     = null
  description = <<-EOT

 ---
 `cors_rule` block supports the following:
 - `allowed_headers` - (Required) A list of headers that are allowed to be a part of the cross-origin request.
 - `allowed_methods` - (Required) A list of HTTP methods that are allowed to be executed by the origin. Valid options are `DELETE`, `GET`, `HEAD`, `MERGE`, `POST`, `OPTIONS`, `PUT` or `PATCH`.
 - `allowed_origins` - (Required) A list of origin domains that will be allowed by CORS.
 - `exposed_headers` - (Required) A list of response headers that are exposed to CORS clients.
 - `max_age_in_seconds` - (Required) The number of seconds the client should cache a preflight response.

 ---
 `retention_policy` block supports the following:
 - `days` - (Optional) Specifies the number of days that the `azurerm_storage_share` should be retained, between `1` and `365` days. Defaults to `7`.

 ---
 `smb` block supports the following:
 - `authentication_types` - (Optional) A set of SMB authentication methods. Possible values are `NTLMv2`, and `Kerberos`.
 - `channel_encryption_type` - (Optional) A set of SMB channel encryption. Possible values are `AES-128-CCM`, `AES-128-GCM`, and `AES-256-GCM`.
 - `kerberos_ticket_encryption_type` - (Optional) A set of Kerberos ticket encryption. Possible values are `RC4-HMAC`, and `AES-256`.
 - `multichannel_enabled` - (Optional) Indicates whether multichannel is enabled. Defaults to `false`. This is only supported on Premium storage accounts.
EOT
}

variable "shared_access_key_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key. If false, then all requests, including shared access signatures, must be authorized with Azure Active Directory (Azure AD). The default value is `true`."
}

variable "static_website" {
  type = object({
    error_404_document = optional(string)
    index_document     = optional(string)
  })
  default     = null
  description = <<-EOT
 - `error_404_document` - (Optional) The absolute path to a custom webpage that should be used when a request is made which does not correspond to an existing file.
 - `index_document` - (Optional) The webpage that Azure Storage serves for requests to the root of a website or any subfolder. For example, index.html. The value is case-sensitive.
EOT
}

variable "storage_account_location" {
  type        = string
  description = "(Required) Specifies the supported Azure location where the resource exists. Defaults to the Resource Group location. Changing this forces a new resource to be created."
  default     = null
}

variable "storage_account_local_user" {
  type = map(object({
    home_directory       = optional(string)
    name                 = string
    ssh_key_enabled      = optional(bool)
    ssh_password_enabled = optional(bool)
    permission_scope = optional(list(object({
      resource_name = string
      service       = string
      permissions = object({
        create = optional(bool)
        delete = optional(bool)
        list   = optional(bool)
        read   = optional(bool)
        write  = optional(bool)
      })
    })))
    ssh_authorized_key = optional(list(object({
      description = optional(string)
      key         = string
    })))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  }))
  default     = {}
  description = <<-EOT
 - `home_directory` - (Optional) The home directory of the Storage Account Local User.
 - `name` - (Required) The name which should be used for this Storage Account Local User. Changing this forces a new Storage Account Local User to be created.
 - `ssh_key_enabled` - (Optional) Specifies whether SSH Key Authentication is enabled. Defaults to `false`.
 - `ssh_password_enabled` - (Optional) Specifies whether SSH Password Authentication is enabled. Defaults to `false`.

 ---
 `permission_scope` block supports the following:
 - `resource_name` - (Required) The container name (when `service` is set to `blob`) or the file share name (when `service` is set to `file`), used by the Storage Account Local User.
 - `service` - (Required) The storage service used by this Storage Account Local User. Possible values are `blob` and `file`.

 ---
 `permissions` block supports the following:
 - `create` - (Optional) Specifies if the Local User has the create permission for this scope. Defaults to `false`.
 - `delete` - (Optional) Specifies if the Local User has the delete permission for this scope. Defaults to `false`.
 - `list` - (Optional) Specifies if the Local User has the list permission for this scope. Defaults to `false`.
 - `read` - (Optional) Specifies if the Local User has the read permission for this scope. Defaults to `false`.
 - `write` - (Optional) Specifies if the Local User has the write permission for this scope. Defaults to `false`.

 ---
 `ssh_authorized_key` block supports the following:
 - `description` - (Optional) The description of this SSH authorized key.
 - `key` - (Required) The public key value of this SSH authorized key.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the Storage Account Local User.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Storage Account Local User.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Storage Account Local User.
 - `update` - (Defaults to 30 minutes) Used when updating the Storage Account Local User.
EOT
  nullable    = false
}

variable "storage_account_name" {
  type        = string
  description = "(Required) Specifies the name of the storage account. Only lowercase Alphanumeric characters allowed. Changing this forces a new resource to be created. This must be unique across the entire Azure service, not just within the resource group."
  default     = null
}

variable "storage_container" {
  type = list(object({
    container_access_type = optional(string)
    metadata              = optional(map(string))
    name                  = string
    blob = optional(list(object({
      name           = string
      type           = string
      size           = optional(number, 0)
      access_tier    = optional(string)
      cache_control  = optional(string)
      content_type   = optional(string)
      content_md5    = optional(string)
      source         = optional(string)
      source_content = optional(string)
      source_uri     = optional(string)
      parallelism    = optional(number)
      metadata       = optional(map(string), {})
      timeouts = optional(object({
        create = optional(string)
        delete = optional(string)
        read   = optional(string)
        update = optional(string)
      }))
    })))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  }))
  default     = []
  description = <<-EOT
 - `container_access_type` - (Optional) The Access Level configured for this Container. Possible values are `blob`, `container` or `private`. Defaults to `private`.
 - `metadata` - (Optional) A mapping of MetaData for this Container. All metadata keys should be lowercase.
 - `name` - (Required) The name of the Container which should be created within the Storage Account. Changing this forces a new resource to be created.

---
`blob` block supports the following:
- `name` - (Required) The name of the storage blob. Must be unique within the storage container the blob is located. Changing this forces a new resource to be created.
- `type` - (Required) The type of the storage blob to be created. Possible values are `Append`, `Block` or `Page`. Changing this forces a new resource to be created.
- `size` - (optional) Size is required if source_uri is not set. Used only for `page` blobs to specify the size in bytes of the blob to be created. Must be a multiple of 512. Defaults to `0`. Changing this forces a new resource to be created.
- `access_tier` - (optional) The access tier of the storage blob. Possible values are `Archive`, `Cool` and `Hot`.
- `cache_control` - (optional) Controls the cache control header content of the response when blob is requested .
- `content_type` - (optional) The content type of the storage blob. Cannot be defined if source_uri is defined. Defaults to `application/octet-stream`.
- `content_md5` - (optional) The MD5 sum of the blob contents. Cannot be defined if `source_uri` is defined, or if blob type is `Append` or `Page`. Changing this forces a new resource to be created.
- `source` - (optional) An absolute path to a file on the local system. This field cannot be specified for `Append` blobs and cannot be specified if `source_content` or `source_uri` is specified. Changing this forces a new resource to be created.
- `source_content` - (optional) The content for this blob which should be defined inline. This field can only be specified for Block blobs and cannot be specified if `source` or `source_uri` is specified. Changing this forces a new resource to be created.
- `source_uri` - (optional) The URI of an existing blob, or a file in the Azure File service, to use as the source contents for the blob to be created. Changing this forces a new resource to be created. This field cannot be specified for Append blobs and cannot be specified if `source` or `source_content` is specified.
- `parallelism` - (optional) The number of workers per CPU core to run for concurrent uploads. Defaults to `8`. Currently, only applicable for `Page` blobs. Changing this forces a new resource to be created.
- `metadata` - (Optional) A mapping of MetaData which should be assigned to this Blob.
- `timeouts` block

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the Storage Container.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Storage Container.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Storage Container.
 - `update` - (Defaults to 30 minutes) Used when updating the Storage Container.
EOT
  nullable    = false
}

variable "storage_queue" {
  type = list(object({
    metadata = optional(map(string))
    name     = string
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  }))
  default     = []
  description = <<-EOT
 - `metadata` - (Optional) A mapping of MetaData which should be assigned to this Storage Queue.
 - `name` - (Required) The name of the Queue which should be created within the Storage Account. Must be unique within the storage account the queue is located. Changing this forces a new resource to be created.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the Storage Queue.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Storage Queue.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Storage Queue.
 - `update` - (Defaults to 30 minutes) Used when updating the Storage Queue.
EOT
  nullable    = false
}

variable "storage_share" {
  type = list(object({
    access_tier      = optional(string)
    enabled_protocol = optional(string)
    metadata         = optional(map(string))
    name             = string
    quota            = number
    directories = optional(list(object({
      name = string
      files = optional(list(object({
        name                = string
        source              = optional(string)
        content_type        = optional(string)
        content_md5         = optional(string)
        content_encoding    = optional(string)
        content_disposition = optional(string)
        metadata            = optional(map(string))
        timeouts = optional(object({
          create = optional(string)
          delete = optional(string)
          read   = optional(string)
          update = optional(string)
        }))
      })))
      metadata = optional(map(string), {})
      timeouts = optional(object({
        create = optional(string)
        delete = optional(string)
        read   = optional(string)
        update = optional(string)
      }))
    })))
    acl = optional(set(object({
      id = string
      access_policy = optional(list(object({
        expiry      = optional(string)
        permissions = string
        start       = optional(string)
      })))
    })))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  }))
  default     = []
  description = <<-EOT
 - `access_tier` - (Optional) The access tier of the File Share. Possible values are `Hot`, `Cool` and `TransactionOptimized`, `Premium`.
 - `enabled_protocol` - (Optional) The protocol used for the share. Possible values are `SMB` and `NFS`. The `SMB` indicates the share can be accessed by SMBv3.0, SMBv2.1 and REST. The `NFS` indicates the share can be accessed by NFSv4.1. Defaults to `SMB`. Changing this forces a new resource to be created.
 - `metadata` - (Optional) A mapping of MetaData for this File Share.
 - `name` - (Required) The name of the share. Must be unique within the storage account where the share is located. Changing this forces a new resource to be created.
 - `quota` - (Required) The maximum size of the share, in gigabytes. For Standard storage accounts, this must be `1`GB (or higher) and at most `5120` GB (`5` TB). For Premium FileStorage storage accounts, this must be greater than 100 GB and at most `102400` GB (`100` TB).

---
`directories` block supports the following:
- `name` - (Required) The name (or path) of the Directory that should be created within this File Share. Changing this forces a new resource to be created.
- `files` block

---
`files` block supports the following:
- `name` - (Required) The name (or path) of the File that should be created within this File Share. Changing this forces a new resource to be created.
- `source` - (Optional) An absolute path to a file on the local system. Changing this forces a new resource to be created.
- `content_type` - (Optional) The content type of the share file. Defaults to application/octet-stream. Some possible values are `text/plain`, `application/json`, `application/ms-excel`, `image/png`, `audio/mpeg`, `video/mp4`, etc.
- `content_md5` - (Optional) The MD5 sum of the file contents. Changing this forces a new resource to be created.
- `content_encoding` - (Optional) Specifies which content encodings have been applied to the file. Some possible values are `gzip`, `deflate`, `identity`, `compress`, etc.
- `content_disposition` - (Optional) Sets the file’s Content-Disposition header. Some possible values are `inline`, `attachment`, `filename=example.txt`, etc.
- `metadata` - (Optional) A mapping of metadata to assign to this file.

 ---
 `acl` block supports the following:
 - `id` - (Required) The ID which should be used for this Shared Identifier.

 ---
 `access_policy` block supports the following:
 - `expiry` - (Optional) The time at which this Access Policy should be valid until, in [ISO8601](https://en.wikipedia.org/wiki/ISO_8601) format.
 - `permissions` - (Required) The permissions which should be associated with this Shared Identifier. Possible value is combination of `r` (read), `w` (write), `d` (delete), and `l` (list).
 - `start` - (Optional) The time at which this Access Policy should be valid from, in [ISO8601](https://en.wikipedia.org/wiki/ISO_8601) format.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the Storage Share.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Storage Share.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Storage Share.
 - `update` - (Defaults to 30 minutes) Used when updating the Storage Share.
EOT
  nullable    = false
}

variable "storage_table" {
  type = list(object({
    name = string
    entities = optional(map(object({
      partition_key = string
      row_key       = string
      entity        = map(string)
    })))
    acl = optional(set(object({
      id = string
      access_policy = optional(list(object({
        expiry      = string
        permissions = string
        start       = string
        utc_offset  = optional(string, "-6h")
      })))
    })))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  }))
  default     = []
  description = <<-EOT
 - `name` - (Required) The name of the storage table. Only Alphanumeric characters allowed, starting with a letter. Must be unique within the storage account the table is located. Changing this forces a new resource to be created.

---
`entities` block supports the following:
- `partition_key` - (Required) The key for the partition where the entity will be retrieved.
- `row_key` - (Required) The key for the row where the entity will be inserted/merged. Changing this forces a new resource.
- `entity` - (Required) A map of key/value pairs that describe the entity to be inserted/merged in to the storage table.

 ---
 `acl` block supports the following:
 - `id` - (Required) The ID which should be used for this Shared Identifier.

 ---
 `access_policy` block supports the following:
 - `expiry` - (Required) The ISO8061 UTC time at which this Access Policy should be valid until.
 - `permissions` - (Required) The permissions which should associated with this Shared Identifier.
 - `start` - (Required) The ISO8061 UTC time at which this Access Policy should be valid from.
 - `utc_offset` - (Optional) The difference in hours and minutes between Coordinated Universal Time and local solar time. Defaults to Central Time Zone utc offset of "-6h".

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the Storage Table.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Storage Table.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Storage Table.
 - `update` - (Defaults to 30 minutes) Used when updating the Storage Table.
EOT
  nullable    = false
}

variable "table_encryption_key_type" {
  type        = string
  default     = "Service"
  description = "(Optional) The encryption type of the table service. Possible values are `Service` and `Account`. Changing this forces a new resource to be created. Default value is `Service`."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags to assign to the resource."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-EOT
 - `create` - (Defaults to 60 minutes) Used when creating the Storage Account.
 - `delete` - (Defaults to 60 minutes) Used when deleting the Storage Account.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Storage Account.
 - `update` - (Defaults to 60 minutes) Used when updating the Storage Account.
EOT
}