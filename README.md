- [Overview](#overview)
- [Data Protection Requirements/Considerations](#data-protection-requirementsconsiderations)
- [High Availability Requirements/Considerations](#high-availability-requirementsconsiderations)
- [Disaster Recovery Requirements/Considerations](#disaster-recovery-requirementsconsiderations)
- [Cloud Platform Organization Policies](#cloud-platform-organization-policies)
- [Hashicorp Sentinel Policies](#hashicorp-sentinel-policies)
- [Permissions Required](#permissions-required)
- [Apis Required](#apis-required)
- [How to Use this Module](#how-to-use-this-module)
- [Create a Standard StorageV2 that has a variety of features](#create-a-standard-storagev2-that-has-a-variety-of-features)
- [Requirements](#requirements)
- [Providers](#providers)
- [Modules](#modules)
- [Resources](#resources)
- [Inputs](#inputs)
- [Outputs](#outputs)

## Azure Storage Account Module

## Overview of the Module

The Azure Storage Account module deploys Azure Storage data objects: Containers, Blobs, Queues, Tables, File Shares, and Data Lake Gen2 storage.

Standard StorageV2 - Standard storage account type for blobs, file shares, queues, and tables. Recommended for most scenarios using Azure Storage.

Premium File Shares - Premium storage account type for Server Message Block (SMB) file shares only. Recommended for enterprise or high-performance scale applications.

Premium Blockblobs - Premium storage account type for block blobs and append blobs. Recommended for scenarios with high transaction rates or that use smaller objects or require consistently low storage latency, e.g., Data Lake Storage for dedicated big data analytics capabilties.

This module was defaults to a Standard StorageV2, with a Hot access tier, and read-access geo-redunant replication. For Premium accounts, account replication must be either locally-redundant (LRS) or zone-redundant (ZRS). 

Remember storage account names must be between 3 and 24 characters, lowercase letters and numbers, and globally unique.

## Data Protection Requirements / Considerations

### Management Locks
- CanNotDelete: Authorized users are able to read and modify the resources, but not delete. Defaults to `true`. The CanNotDelete setting will NOT prevent Terraform from destorying the storage account.
- ReadOnly: Authorized users can only read from a resource, but they can't modify or delete. Defaults to `false`. Once a ReadOnly lock is deployed, no further modifications can take place, including Terraform changes. This lock will have to be removed manually, through the command line, or via the Azure Portal. Navigate to the storage account, and under the left navigation panel, the Settings grouping, select Locks, then delete the lock. Be sure to remove the ReadOnly setting, or set it to `false`, to prevent it from recreating.

### Immutability Policy
The immutability policy can be set at the storage account level, which will be inherited by objects, containers and blobs, that do not possess an explicit immutability policy. Be aware that the initial state can only be 'Disabled' or 'Unlocked', before being put in a 'Locked' state. Once in a 'Locked' state, it cannot be reverted.

### Replacement Triggers
Changing the name for these resources and fields will cause a replace of the resource, resulting in data loss. As a general rule of thumb, changing a resource's name or the name of a parent resource will cause a replacement.

| Resource | Changing this field will force a new resource to be created |
|----------|-----------------------------------|
| azurerm_storage_account | name <br>resource_group_name <br>location <br>account_tier <br>edge_zone <br>enable_https_traffic_only <br>is_hns_enabled <br>nfsv3_enabled <br>queue_encryption_key_type <br>table_encryption_key_type <br>infrastructure_encryption_enabled <br>immutability_policy |
| azurerm_storage_account_network_rules | storage_account_id |
| azurerm_storage_blob_inventory_policy | storage_account_id |
|azurerm_storage_management_policy | storage_account_id |
| azurerm_storage_blob | name <br>storage_account_name <br>storage_container_name <br>type <br>size <br>content_md5 <br>source_content <br>source_uri <br> parallelism |
| azurerm_storage_container | name <br>storage_account_name |
| azurerm_storage_data_lake_gen2_filesystem | name <br>storage_acccount_id |
| azurerm_storage_data_lake_gen2_path | path <br>filesystem_name <br>storage_account_id <br>resource |
| azurerm_storage_queue | name <br>storage_account_name |
| azurerm_storage_share | name <br>storage_account_name |
| azurerm_storage_share_directory | name <br>share_name <br>storage_account_name |
| azurerm_storage_share_file | name <br>storage_share_id <br>path <br>source <br>content_md5 |
| azurerm_storage_table | name <br>storage_account_name |
| azurerm_storage_table_entity | storage_account_name <br>table_name <br>partition_key <br>row_key |

## High Availability Requirements / Considerations

### Account Replication
By default account replication is set to read-access geo-redunant (RAGRS). Possible options for Standard Storage Accounts are:
- LRS: Locally redundant storage
  - least expensive replication option, but data is only copied in a single location in the primary region
- ZRS: Zone-redundant storage
  - copies data across three Azure availability zones in the primary region
- GRS: Geo-redundant storage
  - copies data across three Azure availability zones in the primary region, and in single location in the secondary region
- GZRS: Geo-zone-redundant storage
  - similar to GRS, however data in the secondary region is copied using LRS
- RA-GRS: Read-access Geo-redundant storage
  - similar to GRS, with the added benefit of data always available to be read from the secondary, including in a situation where the primary region becomes unavailable
- RA-GZRS: Read-access Geo-zone-redundant storage
  - similar to GZRS, with the added benefit of data always available to be read from the secondary, including in a situation where the primary region becomes unavailable

For example, Azure Cross-Region Replication has East US 2 paired wtih Central US.

### Premium Accounts
Premium accounts are currently restricted to locally-redundant (LRS) or zone-redundant (ZRS) per Azure capabilities.

## Disaster Recovery Requirements / Considerations

There are two types of failover, Customer-managed and Microsoft-managed. Regardless of failover, some level of data loss should be anticipated, due to a delay between data being written to the primary region before being copied to the secondary. For more information, see the Microsoft documentation [here](https://learn.microsoft.com/en-us/azure/storage/common/storage-disaster-recovery-guidance#anticipate-data-loss-and-inconsistencies).

### Customer-managed Failover
Customer-managed failovers enable you to fail over your entire geo-redundant storage account to the secondary region if the storage service endpoints for the primary region become unavailable. During failover, the original secondary region becomes the new primary and all storage service endpoints for blobs, tables, queues and files are redirected to the new primary region. After the storage service endpoint outage has been resolved, you can perform another failover operation to fail back to the original primary region. For more information, see the Microsoft documentation [here](https://learn.microsoft.com/en-us/azure/storage/common/storage-failover-customer-managed-unplanned?tabs=grs-ra-grs).

### Microsoft-managed Failover
Microsoft-managed failovers are at the region or scale unit level, and can't be initiated for individual storage accounts, subscriptions, or tenants. This happens during extremem circumstances, where the original primary region is deemed unrecoverable.

## Cloud Platform Requirements / Considerations


## Security Requirments / Considerations

### Public Network Access
 If public_network_access_enabled variable is set to true (which is default), then using the network_rules variables, ip_rules can be set to allow access for public ip addresses and ip address ranges, e.g., specific single client, range of VPN users, on-premises networks. Additionally, virtual_network_subnet_ids can specifiy virtual network subnets, allowing access for resources there. Exceptions for access can be allowed for Logging, Metrics, and Azure Services, using the bypass parameter.

 If public_network_access_enabled variable is set to false, then network_rules has no effect.

If leveraging HCP Terraform (formerly Terraform Cloud), and internally owned runners are not being used, then the relevant workspace will need be in local mode, and the user's IP address added to the network_rules ip_rules parameter. This is because the IP addresses for HCP Terraform shared runners are not published, and thus they cannot be reliably be added to the exception listed. For your awareness, HashiCorp does publish ip addresses for other services, via https://app.terraform.io/api/meta/ip-ranges, but they do not have any affect on the runners.

### Terraform Cloud considerations
If leveraging Terraform Cloud there's it's recommended to utilize internal owned runners utilizing HCP Teraform Agents, which is documented [here](https://developer.hashicorp.com/terraform/cloud-docs/agents). The network of machine where the agent is installed can be linked to the storage account, utilizing a service endpoint. A subnet id, an example of an Azure one below, can be added to the network_rules virtual_network_subnet_ids variable.
```hcl
tfc_agent_<region>_subnet_id    = "/subscriptions/<sub_id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<snet>"
```

### Private Endpoings
To enable Private Endpoints, set the enable_private_networking variable to true, and private_endpoint_subnet_id and dns_zone_ids will need to be populated. dns_zone_ids is a map of object with name and id parameters. Optionally, the private_endpoint_resource_group_name variable can be populated if the resource group is different than the resource_group_name variable value.

### Secure Transfer
Secure transfer with HTTPS only traffic can be enforced with the enable_https_traffic_only variable; it currently defaults to true. This is generally recommended, the exception being this must be disabled when using NFS (Network File System) Azure File Shares. Additionally, this setting will not be applied for custom domain names.

### Infrastructure Encryption
Azure Storage automatically encrypts all data in a storage account at the service level using 256-bit AES with GCM (Galois/Counter Mode) encryption and is FIPS 140-2 compliant. If compliance requirements require more, an additional layer of 256-bit AES CBC (Cipher Block Chaining) encryption is available using the infrastructure_encryption_enabled variable. This module currently implements only Microsoft-managed keys for this option. Otherwise, enabling this feature may impact peformance, and is irreversibile once set (storage account would have to be destroyed and recreated to turn off this f).

The min_tls_version variable defaults to TLS1.2, and the variable validation currently constrains it to only that value.

## Permissions Required

## API's Required

## How to Use this Module

## Create a Standard StorageV2 that has a variety of features

```hcl
locals {
  tags = {
    env            = "dev"
    app_code       = "storage"
    app_instance   = "storagev2"
    classification = "internal-only"
    cost_id        = "12345"
    department_id  = "678901"
    project_id     = "it-ab00c123"
    org_code       = "insight"
    managed_by     = "terraform"
  }
}

data "azurerm_subnet" "test_sub" {
  name                 = "default"
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.resource_group_name
}

resource "random_id" "random_suffix" {
  byte_length = 8
}

module "azure_storage_account_standard_storagev2" {
  source  = "app.terraform.io/insight/azure-storage/terraform"
  version = "1.0.0"
  
  tags                 = local.tags
  storage_account_name = substr(format("st%s%s%s%s", local.tags.app_code, local.tags.env, local.tags.app_instance, random_id.random_suffix.hex), 0, 24)
  resource_group_name  = var.resource_group_name

  public_network_access_enabled = false
  network_rules = {
    default_action = "Deny"
    # This could be a specific ip address for individual users, e.g., 20.94.5.238
    # or an ip range for a group of users (VPN), e.g., 20.128.0.0/16
    ip_rules                   = ["20.94.5.238"]
    virtual_network_subnet_ids = [data.azurerm_subnet.test_sub.id]
  }

  storage_container = [
    {
      name = "container-append"
      blob = [
        {
          name = "blob_append"
          type = "Append"
          metadata = {
            blob_type = "append"
            purpose   = "logs"
          }
      }]
    },
    {
      name = "container-block"
      blob = [
        {
          name           = "blob_block_first"
          type           = "Block"
          access_tier    = "Hot"
          source_content = "Hello World!"
          metadata = {
            blob_type = "block"
            purpose   = "backups"
          }
        }
      ]
    }
  ]

  blob_properties = {
    versioning_enabled = true
  }

  blob_inventory_policy = [
    {
      name                   = "blob-inventory-policy-rule-blob"
      storage_container_name = "container-append"
      format                 = "Csv"
      schedule               = "Daily"
      scope                  = "Blob"
      schema_fields = [
        "Name",
        "Last-Modified",
        "Metadata",
        "VersionId",
        "IsCurrentVersion"
      ]
      filter = {
        blob_types            = ["blockBlob"]
        include_blob_versions = true
        include_deleted       = false
        include_snapshots     = false
        prefix_match          = ["prefix1", "prefix2"]
        exclude_prefixes      = ["prefix3", "prefix4"]
      }
    },
    {
      name                   = "blob-inventory-policy-rule-blob-expanded"
      storage_container_name = "container-append"
      format                 = "Parquet"
      schedule               = "Weekly"
      scope                  = "Blob"
      schema_fields = [
        "Name",
        "Last-Modified",
        "Metadata",
        "BlobType",
        "AccessTier",
        "LastAccessTime"
      ]
      filter = {
        blob_types = ["appendBlob"]
      }
    },
    {
      name                   = "blob-inventory-policy-rule-container"
      storage_container_name = "container-append"
      format                 = "Csv"
      schedule               = "Weekly"
      scope                  = "Container"
      schema_fields = [
        "Name",
        "Last-Modified",
        "Metadata",
        "PublicAccess",
        "HasImmutabilityPolicy",
        "HasLegalHold",
        "DefaultEncryptionScope"
      ]
    },
    {
      name                   = "blob-inventory-policy-rule-blob-2"
      storage_container_name = "container-block"
      format                 = "Csv"
      schedule               = "Daily"
      scope                  = "Blob"
      schema_fields = [
        "Name",
        "Last-Modified",
        "Metadata"
      ]
      filter = {
        blob_types = ["blockBlob"]
      }
    }
  ]
  management_policy = {
    rule = [
      {
        name    = "firstrule"
        enabled = true
        filters = {
          prefix_match = ["container-block/blob_block"]
          blob_types   = ["blockBlob"]
          match_blob_index_tag = {
            name      = "tag1"
            operation = "=="
            value     = "val1"
          }
        }
        actions = {
          base_blob = {
            tier_to_cool_after_days_since_modification_greater_than    = 10
            tier_to_archive_after_days_since_modification_greater_than = 50
            delete_after_days_since_modification_greater_than          = 100
          }
        }
      },
      {
        name    = "secondrule"
        enabled = true
        filters = {
          prefix_match = ["container-block-page-combo/blob_block"]
          blob_types   = ["blockBlob"]
        }
        actions = {
          snapshot = {
            delete_after_days_since_creation_greater_than = 30
          }
          version = {
            delete_after_days_since_creation = 60
          }
        }
      }
    ]
  }

  storage_queue = [
    {
      name = "queue-first"
      metadata = {
        testkey        = "testvalue"
        queuetype      = module.azure_storage_account_standard_storagev2.storage_account_tier
        classification = local.tags.classification
      }
    },
    {
      name = "queue-second"
    }
  ]

  queue_properties = {
    cors_rule = [{
      allowed_headers    = ["x-ms-meta-data*", "x-ms-meta-target*"]
      allowed_methods    = ["PUT", "GET"]
      allowed_origins    = ["http://*.contoso.com", "http://www.fabrikam.com"]
      exposed_headers    = ["x-ms-meta-*"]
      max_age_in_seconds = 200
    }]
    logging = {
      delete                = true
      read                  = true
      retention_policy_days = 7
      version               = "1.0"
      write                 = true
    }
    minute_metrics = {
      enabled               = true
      retention_policy_days = 7
      version               = "1.0"
    }
  }

  storage_table = [
    {
      name = "supplies"
      entities = {
        stethoscope = {
          partition_key = "Diagnostic"
          row_key       = "STETH"
          entity = {
            "Equipment"   = "Stethoscope"
            "Description" = "A device used to listen to sounds within the body, such as heart or lung sounds."
            "Use"         = "Used by doctors and nurses to diagnose and monitor various medical conditions."
            "Quantity"    = "235"
          }
        }
        blood_pressure_monitor = {
          partition_key = "Diagnostic"
          row_key       = "BPM"
          entity = {
            "Equipment"   = "Blood pressure monitor"
            "Description" = "A device used to measure the pressure of blood in the arteries."
            "Use"         = "Used to diagnose and monitor high blood pressure (hypertension) and other cardiovascular conditions."
            "Quantity"    = "35"
          }
        },
        surgical_laser = {
          partition_key = "Surgical"
          row_key       = "SURGLAS"
          entity = {
            "Equipment"   = "Surgical laser"
            "Description" = "A device that uses a focused beam of light to cut or vaporize tissue."
            "Use"         = "Used during surgical procedures to make precise incisions, remove tumors, or treat various medical conditions."
            "Quantity"    = "12"
          }
        }
      }
    },
    {
      name = "technicians"
      acl = [
        {
          id = "example-acl-id"
          access_policy = [
            {
              start       = "2024-02-01"
              expiry      = "2025-03-15T14:00:00"
              permissions = "raud"
              utc_offset  = "-5h"
            }
          ]
        }
      ]
    }
  ]

  storage_share = [
    {
      name  = "first-share"
      quota = 1
    },
    {
      name  = "second-share"
      quota = 2
      directories = [
        {
          name = "media"
        },
        {
          name = "images"
          files = [
            {
              name = "logo.png"
            },
            {
              name = "banner.png"
            }
          ]
          metadata = {
            owner   = "Public Affairs"
            purpose = "branding"
          }
        },
        {
          name = "documents"
          files = [
            {
              name                = "README.md"
              source              = "./README.md"
              content_type        = "test/markdown"
              content_md5         = "767f964b6c24295e25e0a5f42e1bfebf"
              content_encoding    = "identity"
              content_disposition = "attachment"
              metadata = {
                description = "Readme"
                filetype    = "markdown"
              }
            }
          ]
        }
      ]
    }
  ]

  share_properties = {
    retention_policy = {
      days = 7
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~>1.3 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~>3.95 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >=3.6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~>3.95 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| azurerm_management_lock.this | resource |
| azurerm_private_endpoint.blob | resource |
| azurerm_private_endpoint.dfs | resource |
| azurerm_private_endpoint.file | resource |
| azurerm_private_endpoint.queue | resource |
| azurerm_private_endpoint.table | resource |
| azurerm_private_endpoint.web | resource |
| azurerm_storage_account.this | resource |
| azurerm_storage_account_local_user.this | resource |
| azurerm_storage_account_network_rules.this | resource |
| azurerm_storage_blob.this | resource |
| azurerm_storage_blob_inventory_policy.this | resource |
| azurerm_storage_container.this | resource |
| azurerm_storage_data_lake_gen2_filesystem.this | resource |
| azurerm_storage_data_lake_gen2_path.this | resource |
| azurerm_storage_management_policy.this | resource |
| azurerm_storage_queue.this | resource |
| azurerm_storage_share.this | resource |
| azurerm_storage_share_directory.this | resource |
| azurerm_storage_share_file.this | resource |
| azurerm_storage_table.this | resource |
| azurerm_storage_table_entity.this | resource |
| azurerm_resource_group.rgrp | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_tier"></a> [access\_tier](#input\_access\_tier) | (Optional) Defines the access tier for `BlobStorage`, `FileStorage` and `StorageV2` accounts. Valid options are `Hot` and `Cool`, defaults to `Hot`. | `string` | `"Hot"` | no |
| <a name="input_account_kind"></a> [account\_kind](#input\_account\_kind) | (Optional) Defines the Kind of account. Valid options are `BlobStorage`, `BlockBlobStorage`, `FileStorage`, `Storage` and `StorageV2`. Defaults to `StorageV2`. | `string` | `"StorageV2"` | no |
| <a name="input_account_replication_type"></a> [account\_replication\_type](#input\_account\_replication\_type) | (Required) Defines the type of replication to use for this storage account. Valid options are `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS` and `RAGZRS`. | `string` | `"RAGRS"` | no |
| <a name="input_account_tier"></a> [account\_tier](#input\_account\_tier) | (Required) Defines the Tier to use for this storage account. Valid options are `Standard` and `Premium`. For `BlockBlobStorage` and `FileStorage` accounts only `Premium` is valid. Changing this forces a new resource to be created. | `string` | `"Standard"` | no |
| <a name="input_allow_nested_items_to_be_public"></a> [allow\_nested\_items\_to\_be\_public](#input\_allow\_nested\_items\_to\_be\_public) | (Optional) Allow or disallow nested items within this Account to opt into being public. Defaults to false. | `bool` | `false` | no |
| <a name="input_allowed_copy_scope"></a> [allowed\_copy\_scope](#input\_allowed\_copy\_scope) | (Optional) Restrict copy to and from Storage Accounts within an AAD tenant or with Private Links to the same VNet. Possible values are `AAD` and `PrivateLink`. | `string` | `null` | no |
| <a name="input_azure_files_authentication"></a> [azure\_files\_authentication](#input\_azure\_files\_authentication) | - `directory_type` - (Required) Specifies the directory service used. Possible values are `AADDS`, `AD` and `AADKERB`.<br><br>---<br>`active_directory` block supports the following:<br>- `domain_guid` - (Required) Specifies the domain GUID.<br>- `domain_name` - (Required) Specifies the primary domain that the AD DNS server is authoritative for.<br>- `domain_sid` - (Required) Specifies the security identifier (SID).<br>- `forest_name` - (Required) Specifies the Active Directory forest.<br>- `netbios_domain_name` - (Required) Specifies the NetBIOS domain name.<br>- `storage_sid` - (Required) Specifies the security identifier (SID) for Azure Storage. | <pre>object({<br>    directory_type = string<br>    active_directory = optional(object({<br>      domain_guid         = string<br>      domain_name         = string<br>      domain_sid          = string<br>      forest_name         = string<br>      netbios_domain_name = string<br>      storage_sid         = string<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_blob_inventory_policy"></a> [blob\_inventory\_policy](#input\_blob\_inventory\_policy) | - `name` - (Required) The name which should be used for this Blob Inventory Policy Rule.<br>- `storage_container_name` - (Required) The storage container name to store the blob inventory files for this rule.<br>- `format` - (Required) The format of the inventory files. Possible values are `Csv` and `Parquet`.<br>- `schedule` - (Required) The inventory schedule applied by this rule. Possible values are `Daily` and `Weekly`.<br>- `scope` - (Required) The scope of the inventory for this rule. Possible values are `Blob` and `Container`.<br>- `schema_fields` - (Required) A list of fields to be included in the inventory. See the Azure API reference Blob Inventory Policies for all the supported fields.<br>- `filter` block<br>- `timeouts` block<br><br>---<br>`filter` block supports the following:<br>- `blob_types ` - (Required) A set of blob types. Possible values are `blockBlob`, `appendBlob`, and `pageBlob`. The storage account with `is_hns_enabled` is true doesn't support `pageBlob`.<br>- `include_blob_versions` - (Optional) Includes blob versions in blob inventory or not? Defaults to `false`.<br>- `include_deleted` - (Optional) Includes deleted blobs in blob inventory or not? Defaults to `false`.<br>- `include_snapshots` - (Optional) Includes blob snapshots in blob inventory or not? Defaults to `false`.<br>- `prefix_match` - (Optional) A set of strings for blob prefixes to be matched. Maximum of 10 blob prefixes.<br>- `exclude_prefixes` - (Optional) A set of strings for blob prefixes to be excluded. Maximum of 10 blob prefixes. | <pre>list(object({<br>    name                   = string<br>    storage_container_name = string<br>    format                 = string<br>    schedule               = string<br>    scope                  = string<br>    schema_fields          = list(string)<br>    filter = optional(object({<br>      blob_types            = set(string)<br>      include_blob_versions = optional(bool, false)<br>      include_deleted       = optional(bool, false)<br>      include_snapshots     = optional(bool, false)<br>      prefix_match          = optional(set(string))<br>      exclude_prefixes      = optional(set(string))<br>    }))<br>  }))</pre> | `null` | no |
| <a name="input_blob_properties"></a> [blob\_properties](#input\_blob\_properties) | - `change_feed_enabled` - (Optional) Is the blob service properties for change feed events enabled? Default to `false`.<br>- `change_feed_retention_in_days` - (Optional) The duration of change feed events retention in days. The possible values are between 1 and 146000 days (400 years). Setting this to null (or omit this in the configuration file) indicates an infinite retention of the change feed.<br>- `default_service_version` - (Optional) The API Version which should be used by default for requests to the Data Plane API if an incoming request doesn't specify an API Version.<br>- `last_access_time_enabled` - (Optional) Is the last access time based tracking enabled? Default to `false`.<br>- `versioning_enabled` - (Optional) Is versioning enabled? Default to `false`.<br><br>---<br>`container_delete_retention_policy` block supports the following:<br>- `days` - (Optional) Specifies the number of days that the container should be retained, between `1` and `365` days. Defaults to `7`.<br><br>---<br>`cors_rule` block supports the following:<br>- `allowed_headers` - (Required) A list of headers that are allowed to be a part of the cross-origin request.<br>- `allowed_methods` - (Required) A list of HTTP methods that are allowed to be executed by the origin. Valid options are `DELETE`, `GET`, `HEAD`, `MERGE`, `POST`, `OPTIONS`, `PUT` or `PATCH`.<br>- `allowed_origins` - (Required) A list of origin domains that will be allowed by CORS.<br>- `exposed_headers` - (Required) A list of response headers that are exposed to CORS clients.<br>- `max_age_in_seconds` - (Required) The number of seconds the client should cache a preflight response.<br><br>---<br>`delete_retention_policy` block supports the following:<br>- `days` - (Optional) Specifies the number of days that the blob should be retained, between `1` and `365` days. Defaults to `7`.<br><br>---<br>`restore_policy` block supports the following:<br>- `days` - (Required) Specifies the number of days that the blob can be restored, between `1` and `365` days. This must be less than the `days` specified for `delete_retention_policy`. | <pre>object({<br>    change_feed_enabled           = optional(bool)<br>    change_feed_retention_in_days = optional(number)<br>    default_service_version       = optional(string)<br>    last_access_time_enabled      = optional(bool)<br>    versioning_enabled            = optional(bool, true)<br>    container_delete_retention_policy = optional(object({<br>      days = optional(number)<br>    }))<br>    cors_rule = optional(list(object({<br>      allowed_headers    = list(string)<br>      allowed_methods    = list(string)<br>      allowed_origins    = list(string)<br>      exposed_headers    = list(string)<br>      max_age_in_seconds = number<br>    })))<br>    delete_retention_policy = optional(object({<br>      days = optional(number)<br>    }))<br>    restore_policy = optional(object({<br>      days = number<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_cross_tenant_replication_enabled"></a> [cross\_tenant\_replication\_enabled](#input\_cross\_tenant\_replication\_enabled) | (Optional) Should cross Tenant replication be enabled? Defaults to false. | `bool` | `false` | no |
| <a name="input_custom_domain"></a> [custom\_domain](#input\_custom\_domain) | - `name` - (Required) The Custom Domain Name to use for the Storage Account, which will be validated by Azure.<br>- `use_subdomain` - (Optional) Should the Custom Domain Name be validated by using indirect CNAME validation? | <pre>object({<br>    name          = string<br>    use_subdomain = optional(bool)<br>  })</pre> | `null` | no |
| <a name="input_data_lake_gen2"></a> [data\_lake\_gen2](#input\_data\_lake\_gen2) | - `name` - (Required) The name of the Data Lake Gen2 File System which should be created within the Storage Account. Must be unique within the storage account the queue is located. Changing this forces a new resource to be created.<br>- `properties` - (Optional) A mapping of Key to Base64-Encoded Values which should be assigned to this Data Lake Gen2 File System.<br>- `ace` - (Optional) One or more ace blocks as defined below to specify the entries for the ACL for the path.<br>- `owner` - (Optional) Specifies the Object ID of the Azure Active Directory User to make the owning user of the root path (i.e. /). Possible values also include $superuser.<br>- `group` - (Optional) Specifies the Object ID of the Azure Active Directory Group to make the owning group of the root path (i.e. /). Possible values also include $superuser.<br><br>---<br>An `ace` block supports the following:<br>- `scope` - (Optional) Specifies whether the ACE represents an access entry or a default entry. Default value is access.<br>- `type` - (Required) Specifies the type of entry. Can be user, group, mask or other.<br>- `id` - (Optional) Specifies the Object ID of the Azure Active Directory User or Group that the entry relates to. Only valid for user or group entries.<br>- `permissions` - (Required) Specifies the permissions for the entry in rwx form. For example, rwx gives full permissions but r-- only gives read permissions.<br>More details on ACLs can be found here: https://docs.microsoft.com/azure/storage/blobs/data-lake-storage-access-control#access-control-lists-on-files-and-directories<br><br>---<br>An `path` block supports the following:<br>- `path` - (Required) The path which should be created within the Data Lake Gen2 File System in the Storage Account. Changing this forces a new resource to be created.<br>- `resource` - (Required) Specifies the type for path to create. Currently only directory is supported. Changing this forces a new resource to be created.<br>- `owner` - (Optional) Specifies the Object ID of the Azure Active Directory User to make the owning user. Possible values also include $superuser.<br>- `group` - (Optional) Specifies the Object ID of the Azure Active Directory Group to make the owning group. Possible values also include $superuser.<br>- `ace` - (Optional) One or more ace blocks as defined below to specify the entries for the ACL for the path.<br><br>---<br>The `timeouts` block supports the following:<br>- `create` - (Defaults to 30 minutes) Used when creating the Data Lake Gen2 File System.<br>- `update` - (Defaults to 30 minutes) Used when updating the Data Lake Gen2 File System.<br>- `read` - (Defaults to 5 minutes) Used when retrieving the Data Lake Gen2 File System.<br>- `delete` - (Defaults to 30 minutes) Used when deleting the Data Lake Gen2 File System. | <pre>list(object({<br>    name       = string<br>    properties = optional(map(string))<br>    ace = optional(list(object({<br>      scope       = optional(string)<br>      type        = string<br>      id          = optional(string)<br>      permissions = string<br>    })))<br>    owner = optional(string)<br>    group = optional(string)<br>    directory = optional(list(object({<br>      path  = string<br>      owner = optional(string)<br>      group = optional(string)<br>      ace = optional(list(object({<br>        scope       = optional(string)<br>        type        = string<br>        id          = optional(string)<br>        permissions = string<br>      })))<br>    })))<br>    timeouts = optional(object({<br>      create = optional(string)<br>      update = optional(string)<br>      read   = optional(string)<br>      delete = optional(string)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_default_to_oauth_authentication"></a> [default\_to\_oauth\_authentication](#input\_default\_to\_oauth\_authentication) | (Optional) Default to Azure Active Directory authorization in the Azure portal when accessing the Storage Account. The default value is `false` | `bool` | `false` | no |
| <a name="input_dns_zone_ids"></a> [dns\_zone\_ids](#input\_dns\_zone\_ids) | A Map of DNS zone ids from the private DNS zones module, dns\_zone name is the key | <pre>map(object({<br>    name = string<br>    id   = string<br>  }))</pre> | `{}` | no |
| <a name="input_edge_zone"></a> [edge\_zone](#input\_edge\_zone) | (Optional) Specifies the Edge Zone within the Azure Region where this Storage Account should exist. Changing this forces a new Storage Account to be created. | `string` | `null` | no |
| <a name="input_enable_https_traffic_only"></a> [enable\_https\_traffic\_only](#input\_enable\_https\_traffic\_only) | (Optional) Boolean flag which forces HTTPS if enabled, see here for more information. Defaults to true. | `bool` | `true` | no |
| <a name="input_enable_private_networking"></a> [enable\_private\_networking](#input\_enable\_private\_networking) | Declare whether Private Networking should be leveraged (VNet integration and Private Endpoints). | `bool` | `false` | no |
| <a name="input_identity"></a> [identity](#input\_identity) | - `identity_ids` - (Optional) Specifies a list of User Assigned Managed Identity IDs to be assigned to this Storage Account.<br>- `type` - (Required) Specifies the type of Managed Service Identity that should be configured on this Storage Account. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned` (to enable both). | <pre>object({<br>    identity_ids = optional(map(string))<br>    type         = string<br>  })</pre> | `null` | no |
| <a name="input_immutability_policy"></a> [immutability\_policy](#input\_immutability\_policy) | - `allow_protected_append_writes` - (Required) When enabled, new blocks can be written to an append blob while maintaining immutability protection and compliance. Only new blocks can be added and any existing blocks cannot be modified or deleted.<br>- `period_since_creation_in_days` - (Required) The immutability period for the blobs in the container since the policy creation, in days.<br>- `state` - (Required) Defines the mode of the policy. `Disabled` state disables the policy, `Unlocked` state allows increase and decrease of immutability retention time and also allows toggling allowProtectedAppendWrites property, `Locked` state only allows the increase of the immutability retention time. A policy can only be created in a Disabled or Unlocked state and can be toggled between the two states. Only a policy in an Unlocked state can transition to a Locked state which cannot be reverted. | <pre>object({<br>    allow_protected_append_writes = bool<br>    period_since_creation_in_days = number<br>    state                         = string<br>  })</pre> | `null` | no |
| <a name="input_infrastructure_encryption_enabled"></a> [infrastructure\_encryption\_enabled](#input\_infrastructure\_encryption\_enabled) | (Optional) Is infrastructure encryption enabled? Changing this forces a new resource to be created. Defaults to false. | `bool` | `false` | no |
| <a name="input_is_hns_enabled"></a> [is\_hns\_enabled](#input\_is\_hns\_enabled) | (Optional) Is Hierarchical Namespace enabled? This can be used with Azure Data Lake Storage Gen 2 ([see here for more information](https://docs.microsoft.com/azure/storage/blobs/data-lake-storage-quickstart-create-account/)). Changing this forces a new resource to be created. | `bool` | `false` | no |
| <a name="input_large_file_share_enabled"></a> [large\_file\_share\_enabled](#input\_large\_file\_share\_enabled) | (Optional) Is Large File Share Enabled? | `bool` | `null` | no |
| <a name="input_management_locks"></a> [management\_locks](#input\_management\_locks) | A map of management locks<br>- `CanNotDelete` - (Required) Storage Account level CanNotDelete Management Lock. Authorized users are able to read and modify the resources, but not delete. Defaults to `true`. Changing this forces a new resource to be created.<br>- `ReadyOnly` - (Optional) Storage Account level ReadOnly Management Lock. Authorized users can only read from a resource, but they can't modify or delete. Defaults to `false`. Changing this forces a new resource to be created. | <pre>object({<br>    CanNotDelete = bool<br>    ReadOnly     = optional(bool)<br>  })</pre> | <pre>{<br>  "CanNotDelete": true,<br>  "ReadOnly": false<br>}</pre> | no |
| <a name="input_management_policy"></a> [management\_policy](#input\_management\_policy) | `rule` block supports the following:<br> - `name` - (Required) The name of the rule. Rule name is case-sensitive. It must be unique within a policy.<br> - `enabled` - (Required) Boolean to specify whether the rule is enabled.<br> - `filters` - (Required) A filters block as documented below.<br> - `actions` - (Required) An actions block as documented below.<br><br> ---<br> `filters` block supports the following:<br> - `blob_types` - (Required) An array of predefined values. Valid options are `blockBlob` and `appendBlob`.<br> - `prefix_match` - (Optional) An array of strings for prefixes to be matched.<br> - `match_blob_index_tag` - (Optional) A match\_blob\_index\_tag object as defined below. The object defines the blob index tag based filtering for blob objects.<br> Note: The `match_blob_index_tag` block cannot be set if the snapshot and/or version blocks are set.<br><br>---<br>`match_blob_index_tag` block supports the following<br>- `name` - (Required) The filter tag name used for tag based filtering for blob objects.<br>- `operation` - (Optional) The comparison operator which is used for object comparison and filtering. Possible value is ==. Defaults to ==.<br>- `value` - (Required) The filter tag value used for tag based filtering for blob objects.<br><br> ---<br> `actions` block supports the following:<br> - `base_blob` - (Optional) A base\_blob block as documented below.<br> - `snapshot` - (Optional) A snapshot block as documented below.<br> - `version` - (Optional) A version block as documented below.<br><br> ---<br> `base_blob` block supports the following:<br> - `tier_to_cool_after_days_since_modification_greater_than` - (Optional) The age in days after last modification to tier blobs to cool storage. Supports blob currently at Hot tier. Must be between 0 and 99999. Defaults to -1.<br> - `tier_to_cool_after_days_since_last_access_time_greater_than` - (Optional) The age in days after last access time to tier blobs to cool storage. Supports blob currently at Hot tier. Must be between 0 and 99999. Defaults to -1.<br> - `tier_to_cool_after_days_since_creation_greater_than` - (Optional) The age in days after creation to cool storage. Supports blob currently at Hot tier. Must be between 0 and 99999. Defaults to -1.<br> Note: The `tier_to_cool_after_days_since_modification_greater_than`, `tier_to_cool_after_days_since_last_access_time_greater_than`, and `tier_to_cool_after_days_since_creation_greater_than` can not be set at the same time.<br><br> - `auto_tier_to_hot_from_cool_enabled` - (Optional) Whether a blob should automatically be tiered from cool back to hot if it's accessed again after being tiered to cool. Defaults to false.<br> Note: The `auto_tier_to_hot_from_cool_enabled` must be used together with `tier_to_cool_after_days_since_last_access_time_greater_than`.<br><br> - `tier_to_archive_after_days_since_modification_greater_than` - (Optional) The age in days after last modification to tier blobs to archive storage. Supports blob currently at Hot or Cool tier. Must be between 0 and 99999. Defaults to -1.<br> - `tier_to_archive_after_days_since_last_access_time_greater_than` - (Optional) The age in days after last access time to tier blobs to archive storage. Supports blob currently at Hot or Cool tier. Must be between 0 and 99999. Defaults to -1.<br> Note: The `tier_to_archive_after_days_since_modification_greater_than`, `tier_to_archive_after_days_since_last_access_time_greater_than`, and `tier_to_archive_after_days_since_creation_greater_than` can not be set at the same time.<br><br> - `tier_to_archive_after_days_since_last_tier_change_greater_than` - (Optional) The age in days after last tier change to the blobs to skip to be archived. Must be between 0 and 99999. Defaults to -1.<br> Note: The `tier_to_cool_after_days_since_modification_greater_than`, `tier_to_cool_after_days_since_last_access_time_greater_than`, and `tier_to_cool_after_days_since_creation_greater_than` can not be set at the same time.<br><br> - `delete_after_days_since_modification_greater_than` - (Optional) The age in days after last modification to delete the blob. Must be between 0 and 99999. Defaults to -1.<br> - `delete_after_days_since_last_access_time_greater_than` - (Optional) The age in days after last access time to delete the blob. Must be between 0 and 99999. Defaults to -1.<br> - `delete_after_days_since_creation_greater_than` - (Optional) The age in days after creation to delete the blob. Must be between 0 and 99999. Defaults to -1.<br> Note: The `delete_after_days_since_modification_greater_than`, `delete_after_days_since_last_access_time_greater_than`, and `delete_after_days_since_creation_greater_than` can not be set at the same time.<br> Note: The `last_access_time_enabled` must be set to true in the `azurerm_storage_account` in order to use `tier_to_cool_after_days_since_last_access_time_greater_than`, `tier_to_archive_after_days_since_last_access_time_greater_than`, and `delete_after_days_since_last_access_time_greater_than`.<br><br> ---<br> `snapshot` block supports the following:<br> - `change_tier_to_archive_after_days_since_creation` - (Optional) The age in days after creation to tier blob snapshot to archive storage. Must be between 0 and 99999. Defaults to -1.<br> - `tier_to_archive_after_days_since_last_tier_change_greater_than` - (Optional) The age in days after last tier change to the blobs to skip to be archived. Must be between 0 and 99999. Defaults to -1.<br> - `change_tier_to_cool_after_days_since_creation` - (Optional) The age in days after creation to tier blob snapshot to cool storage. Must be between 0 and 99999. Defaults to -1.<br> - `delete_after_days_since_creation`- (Optional) The age in days after creation to delete the blob version. Must be between 0 and 99999. Defaults to -1.<br><br> ---<br> `timeouts` block supports the following:<br> - `create` - (Defaults to 60 minutes) Used when creating the  Network Rules for this Storage Account.<br> - `delete` - (Defaults to 60 minutes) Used when deleting the Network Rules for this Storage Account.<br> - `read` - (Defaults to 5 minutes) Used when retrieving the Network Rules for this Storage Account.<br> - `update` - (Defaults to 60 minutes) Used when updating the Network Rules for this Storage Account. | <pre>object({<br>    rule = optional(list(object({<br>      name    = string<br>      enabled = bool<br>      filters = object({<br>        blob_types   = list(string)<br>        prefix_match = optional(list(string))<br>        match_blob_index_tag = optional(object({<br>          name      = string<br>          operation = optional(string, "==")<br>          value     = string<br>        }))<br>      })<br>      actions = object({<br>        base_blob = optional(object({<br>          tier_to_cool_after_days_since_modification_greater_than        = optional(number)<br>          tier_to_cool_after_days_since_last_access_time_greater_than    = optional(number)<br>          tier_to_cool_after_days_since_creation_greater_than            = optional(number)<br>          auto_tier_to_hot_from_cool_enabled                             = optional(bool)<br>          tier_to_archive_after_days_since_modification_greater_than     = optional(number)<br>          tier_to_archive_after_days_since_last_access_time_greater_than = optional(number)<br>          tier_to_archive_after_days_since_creation_greater_than         = optional(number)<br>          tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)<br>          delete_after_days_since_modification_greater_than              = optional(number)<br>          delete_after_days_since_last_access_time_greater_than          = optional(number)<br>          delete_after_days_since_creation_greater_than                  = optional(number)<br>        }))<br>        snapshot = optional(object({<br>          change_tier_to_archive_after_days_since_creation               = optional(number)<br>          tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)<br>          change_tier_to_cool_after_days_since_creation                  = optional(number)<br>          delete_after_days_since_creation_greater_than                  = optional(number)<br>        }))<br>        version = optional(object({<br>          change_tier_to_archive_after_days_since_creation               = optional(number)<br>          tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)<br>          change_tier_to_cool_after_days_since_creation                  = optional(number)<br>          delete_after_days_since_creation                               = optional(number)<br>        }))<br>      })<br>    })))<br>    timeouts = optional(object({<br>      create = optional(string)<br>      delete = optional(string)<br>      read   = optional(string)<br>      update = optional(string)<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_min_tls_version"></a> [min\_tls\_version](#input\_min\_tls\_version) | (Optional) The minimum supported TLS version for the storage account. Defaults to `TLS1_2` for new storage accounts. | `string` | `"TLS1_2"` | no |
| <a name="input_network_rules"></a> [network\_rules](#input\_network\_rules) | - `default_action` - (Optional) Specifies the default action of allow or deny when no other rules match. Valid options are Deny or Allow. Defaults to Deny.<br>- `bypass` - (Optional) Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Valid options are any combination of `Logging`, `Metrics`, `AzureServices`, or `None`.<br>- `ip_rules` - (Optional) List of public IP or IP ranges in CIDR Format. Only IPv4 addresses are allowed. Private IP address ranges (as defined in [RFC 1918](https://tools.ietf.org/html/rfc1918#section-3)) are not allowed.<br>- `storage_account_id` - (Required) Specifies the ID of the storage account. Changing this forces a new resource to be created.<br>- `virtual_network_subnet_ids` - (Optional) A list of virtual network subnet ids to secure the storage account.<br>- `subnet_id` - (Required) The ID of the Subnet from which Private IP Addresses will be allocated for this Private Endpoint. Changing this forces a new resource to be created.<br><br>---<br>`private_link_access` block supports the following:<br>- `endpoint_resource_id` - (Required) The resource id of the resource access rule to be granted access.<br>- `endpoint_tenant_id` - (Optional) The tenant id of the resource of the resource access rule to be granted access. Defaults to the current tenant id.<br><br>---<br>`timeouts` block supports the following:<br>- `create` - (Defaults to 60 minutes) Used when creating the  Network Rules for this Storage Account.<br>- `delete` - (Defaults to 60 minutes) Used when deleting the Network Rules for this Storage Account.<br>- `read` - (Defaults to 5 minutes) Used when retrieving the Network Rules for this Storage Account.<br>- `update` - (Defaults to 60 minutes) Used when updating the Network Rules for this Storage Account. | <pre>object({<br>    default_action             = optional(string, "Deny")<br>    bypass                     = optional(set(string), ["Logging", "Metrics", "AzureServices"])<br>    ip_rules                   = optional(list(string), [])<br>    virtual_network_subnet_ids = optional(set(string))<br>    private_link_access = optional(list(object({<br>      endpoint_resource_id = string<br>      endpoint_tenant_id   = optional(string)<br>    })))<br>    timeouts = optional(object({<br>      create = optional(string)<br>      delete = optional(string)<br>      read   = optional(string)<br>      update = optional(string)<br>    }))<br>  })</pre> | `{}` | no |
| <a name="input_nfsv3_enabled"></a> [nfsv3\_enabled](#input\_nfsv3\_enabled) | (Optional) Is NFSv3 protocol enabled? Changing this forces a new resource to be created. Defaults to `false`. | `bool` | `false` | no |
| <a name="input_private_endpoint_resource_group_name"></a> [private\_endpoint\_resource\_group\_name](#input\_private\_endpoint\_resource\_group\_name) | The name of the resource group where the private endpoint resources will be deployed. | `string` | `""` | no |
| <a name="input_private_endpoint_subnet_id"></a> [private\_endpoint\_subnet\_id](#input\_private\_endpoint\_subnet\_id) | The ID of the subnet for the Private Endpoint. | `string` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | (Optional) Whether the public network access is enabled? Defaults to `true`. | `bool` | `true` | no |
| <a name="input_queue_encryption_key_type"></a> [queue\_encryption\_key\_type](#input\_queue\_encryption\_key\_type) | (Optional) The encryption type of the queue service. Possible values are `Service` and `Account`. Changing this forces a new resource to be created. Default value is `Service`. | `string` | `"Service"` | no |
| <a name="input_queue_properties"></a> [queue\_properties](#input\_queue\_properties) | ---<br>`cors_rule` block supports the following:<br>- `allowed_headers` - (Required) A list of headers that are allowed to be a part of the cross-origin request.<br>- `allowed_methods` - (Required) A list of HTTP methods that are allowed to be executed by the origin. Valid options are `DELETE`, `GET`, `HEAD`, `MERGE`, `POST`, `OPTIONS`, `PUT` or `PATCH`.<br>- `allowed_origins` - (Required) A list of origin domains that will be allowed by CORS.<br>- `exposed_headers` - (Required) A list of response headers that are exposed to CORS clients.<br>- `max_age_in_seconds` - (Required) The number of seconds the client should cache a preflight response.<br><br>---<br>`hour_metrics` block supports the following:<br>- `enabled` - (Required) Indicates whether hour metrics are enabled for the Queue service.<br>- `include_apis` - (Optional) Indicates whether metrics should generate summary statistics for called API operations.<br>- `retention_policy_days` - (Optional) Specifies the number of days that logs will be retained.<br>- `version` - (Required) The version of storage analytics to configure.<br><br>---<br>`logging` block supports the following:<br>- `delete` - (Required) Indicates whether all delete requests should be logged.<br>- `read` - (Required) Indicates whether all read requests should be logged.<br>- `retention_policy_days` - (Optional) Specifies the number of days that logs will be retained.<br>- `version` - (Required) The version of storage analytics to configure.<br>- `write` - (Required) Indicates whether all write requests should be logged.<br><br>---<br>`minute_metrics` block supports the following:<br>- `enabled` - (Required) Indicates whether minute metrics are enabled for the Queue service.<br>- `include_apis` - (Optional) Indicates whether metrics should generate summary statistics for called API operations.<br>- `retention_policy_days` - (Optional) Specifies the number of days that logs will be retained.<br>- `version` - (Required) The version of storage analytics to configure. | <pre>object({<br>    cors_rule = optional(list(object({<br>      allowed_headers    = list(string)<br>      allowed_methods    = list(string)<br>      allowed_origins    = list(string)<br>      exposed_headers    = list(string)<br>      max_age_in_seconds = number<br>    })))<br>    hour_metrics = optional(object({<br>      enabled               = bool<br>      include_apis          = optional(bool)<br>      retention_policy_days = optional(number)<br>      version               = string<br>    }))<br>    logging = optional(object({<br>      delete                = bool<br>      read                  = bool<br>      retention_policy_days = number<br>      version               = string<br>      write                 = bool<br>    }))<br>    minute_metrics = optional(object({<br>      enabled               = bool<br>      include_apis          = optional(bool)<br>      retention_policy_days = number<br>      version               = string<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) The name of the resource group in which to create the storage account. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_routing"></a> [routing](#input\_routing) | - `choice` - (Optional) Specifies the kind of network routing opted by the user. Possible values are `InternetRouting` and `MicrosoftRouting`. Defaults to `MicrosoftRouting`.<br>- `publish_internet_endpoints` - (Optional) Should internet routing storage endpoints be published? Defaults to `false`.<br>- `publish_microsoft_endpoints` - (Optional) Should Microsoft routing storage endpoints be published? Defaults to `false`. | <pre>object({<br>    choice                      = optional(string)<br>    publish_internet_endpoints  = optional(bool)<br>    publish_microsoft_endpoints = optional(bool)<br>  })</pre> | `null` | no |
| <a name="input_sas_policy"></a> [sas\_policy](#input\_sas\_policy) | - `expiration_action` - (Optional) The SAS expiration action. The only possible value is `Log` at this moment. Defaults to `Log`.<br>- `expiration_period` - (Required) The SAS expiration period in format of `DD.HH:MM:SS`. | <pre>object({<br>    expiration_action = optional(string, "Log")<br>    expiration_period = string<br>  })</pre> | <pre>{<br>  "expiration_period": "00.01:00:00"<br>}</pre> | no |
| <a name="input_sftp_enabled"></a> [sftp\_enabled](#input\_sftp\_enabled) | (Optional) Boolean, enable SFTP for the storage account | `bool` | `false` | no |
| <a name="input_share_properties"></a> [share\_properties](#input\_share\_properties) | ---<br>`cors_rule` block supports the following:<br>- `allowed_headers` - (Required) A list of headers that are allowed to be a part of the cross-origin request.<br>- `allowed_methods` - (Required) A list of HTTP methods that are allowed to be executed by the origin. Valid options are `DELETE`, `GET`, `HEAD`, `MERGE`, `POST`, `OPTIONS`, `PUT` or `PATCH`.<br>- `allowed_origins` - (Required) A list of origin domains that will be allowed by CORS.<br>- `exposed_headers` - (Required) A list of response headers that are exposed to CORS clients.<br>- `max_age_in_seconds` - (Required) The number of seconds the client should cache a preflight response.<br><br>---<br>`retention_policy` block supports the following:<br>- `days` - (Optional) Specifies the number of days that the `azurerm_storage_share` should be retained, between `1` and `365` days. Defaults to `7`.<br><br>---<br>`smb` block supports the following:<br>- `authentication_types` - (Optional) A set of SMB authentication methods. Possible values are `NTLMv2`, and `Kerberos`.<br>- `channel_encryption_type` - (Optional) A set of SMB channel encryption. Possible values are `AES-128-CCM`, `AES-128-GCM`, and `AES-256-GCM`.<br>- `kerberos_ticket_encryption_type` - (Optional) A set of Kerberos ticket encryption. Possible values are `RC4-HMAC`, and `AES-256`.<br>- `multichannel_enabled` - (Optional) Indicates whether multichannel is enabled. Defaults to `false`. This is only supported on Premium storage accounts.<br>- `versions` - (Optional) A set of SMB protocol versions. Possible values are SMB2.1, SMB3.0, and SMB3.1.1. | <pre>object({<br>    cors_rule = optional(list(object({<br>      allowed_headers    = list(string)<br>      allowed_methods    = list(string)<br>      allowed_origins    = list(string)<br>      exposed_headers    = list(string)<br>      max_age_in_seconds = number<br>    })))<br>    retention_policy = optional(object({<br>      days = optional(number)<br>    }))<br>    smb = optional(object({<br>      authentication_types            = optional(set(string))<br>      channel_encryption_type         = optional(set(string))<br>      kerberos_ticket_encryption_type = optional(set(string))<br>      multichannel_enabled            = optional(bool)<br>      versions                        = optional(set(string))<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_shared_access_key_enabled"></a> [shared\_access\_key\_enabled](#input\_shared\_access\_key\_enabled) | (Optional) Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key. If false, then all requests, including shared access signatures, must be authorized with Azure Active Directory (Azure AD). The default value is `true`. | `bool` | `true` | no |
| <a name="input_static_website"></a> [static\_website](#input\_static\_website) | - `error_404_document` - (Optional) The absolute path to a custom webpage that should be used when a request is made which does not correspond to an existing file.<br>- `index_document` - (Optional) The webpage that Azure Storage serves for requests to the root of a website or any subfolder. For example, index.html. The value is case-sensitive. | <pre>object({<br>    error_404_document = optional(string)<br>    index_document     = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_storage_account_local_user"></a> [storage\_account\_local\_user](#input\_storage\_account\_local\_user) | - `home_directory` - (Optional) The home directory of the Storage Account Local User.<br>- `name` - (Required) The name which should be used for this Storage Account Local User. Changing this forces a new Storage Account Local User to be created.<br>- `ssh_key_enabled` - (Optional) Specifies whether SSH Key Authentication is enabled. Defaults to `false`.<br>- `ssh_password_enabled` - (Optional) Specifies whether SSH Password Authentication is enabled. Defaults to `false`.<br><br>---<br>`permission_scope` block supports the following:<br>- `resource_name` - (Required) The container name (when `service` is set to `blob`) or the file share name (when `service` is set to `file`), used by the Storage Account Local User.<br>- `service` - (Required) The storage service used by this Storage Account Local User. Possible values are `blob` and `file`.<br><br>---<br>`permissions` block supports the following:<br>- `create` - (Optional) Specifies if the Local User has the create permission for this scope. Defaults to `false`.<br>- `delete` - (Optional) Specifies if the Local User has the delete permission for this scope. Defaults to `false`.<br>- `list` - (Optional) Specifies if the Local User has the list permission for this scope. Defaults to `false`.<br>- `read` - (Optional) Specifies if the Local User has the read permission for this scope. Defaults to `false`.<br>- `write` - (Optional) Specifies if the Local User has the write permission for this scope. Defaults to `false`.<br><br>---<br>`ssh_authorized_key` block supports the following:<br>- `description` - (Optional) The description of this SSH authorized key.<br>- `key` - (Required) The public key value of this SSH authorized key.<br><br>---<br>`timeouts` block supports the following:<br>- `create` - (Defaults to 30 minutes) Used when creating the Storage Account Local User.<br>- `delete` - (Defaults to 30 minutes) Used when deleting the Storage Account Local User.<br>- `read` - (Defaults to 5 minutes) Used when retrieving the Storage Account Local User.<br>- `update` - (Defaults to 30 minutes) Used when updating the Storage Account Local User. | <pre>map(object({<br>    home_directory       = optional(string)<br>    name                 = string<br>    ssh_key_enabled      = optional(bool)<br>    ssh_password_enabled = optional(bool)<br>    permission_scope = optional(list(object({<br>      resource_name = string<br>      service       = string<br>      permissions = object({<br>        create = optional(bool)<br>        delete = optional(bool)<br>        list   = optional(bool)<br>        read   = optional(bool)<br>        write  = optional(bool)<br>      })<br>    })))<br>    ssh_authorized_key = optional(list(object({<br>      description = optional(string)<br>      key         = string<br>    })))<br>    timeouts = optional(object({<br>      create = optional(string)<br>      delete = optional(string)<br>      read   = optional(string)<br>      update = optional(string)<br>    }))<br>  }))</pre> | `{}` | no |
| <a name="input_storage_account_location"></a> [storage\_account\_location](#input\_storage\_account\_location) | (Required) Specifies the supported Azure location where the resource exists. Defaults to the Resource Group location. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | (Required) Specifies the name of the storage account. Only lowercase Alphanumeric characters allowed. Changing this forces a new resource to be created. This must be unique across the entire Azure service, not just within the resource group. | `string` | n/a | yes |
| <a name="input_storage_container"></a> [storage\_container](#input\_storage\_container) | - `container_access_type` - (Optional) The Access Level configured for this Container. Possible values are `blob`, `container` or `private`. Defaults to `private`.<br> - `metadata` - (Optional) A mapping of MetaData for this Container. All metadata keys should be lowercase.<br> - `name` - (Required) The name of the Container which should be created within the Storage Account. Changing this forces a new resource to be created.<br><br>---<br>`blob` block supports the following:<br>- `name` - (Required) The name of the storage blob. Must be unique within the storage container the blob is located. Changing this forces a new resource to be created.<br>- `type` - (Required) The type of the storage blob to be created. Possible values are `Append`, `Block` or `Page`. Changing this forces a new resource to be created.<br>- `size` - (optional) Size is required if source\_uri is not set. Used only for `page` blobs to specify the size in bytes of the blob to be created. Must be a multiple of 512. Defaults to `0`. Changing this forces a new resource to be created.<br>- `access_tier` - (optional) The access tier of the storage blob. Possible values are `Archive`, `Cool` and `Hot`.<br>- `cache_control` - (optional) Controls the cache control header content of the response when blob is requested .<br>- `content_type` - (optional) The content type of the storage blob. Cannot be defined if source\_uri is defined. Defaults to `application/octet-stream`.<br>- `content_md5` - (optional) The MD5 sum of the blob contents. Cannot be defined if `source_uri` is defined, or if blob type is `Append` or `Page`. Changing this forces a new resource to be created.<br>- `source` - (optional) An absolute path to a file on the local system. This field cannot be specified for `Append` blobs and cannot be specified if `source_content` or `source_uri` is specified. Changing this forces a new resource to be created.<br>- `source_content` - (optional) The content for this blob which should be defined inline. This field can only be specified for Block blobs and cannot be specified if `source` or `source_uri` is specified. Changing this forces a new resource to be created.<br>- `source_uri` - (optional) The URI of an existing blob, or a file in the Azure File service, to use as the source contents for the blob to be created. Changing this forces a new resource to be created. This field cannot be specified for Append blobs and cannot be specified if `source` or `source_content` is specified.<br>- `parallelism` - (optional) The number of workers per CPU core to run for concurrent uploads. Defaults to `8`. Currently, only applicable for `Page` blobs. Changing this forces a new resource to be created.<br>- `metadata` - (Optional) A mapping of MetaData which should be assigned to this Blob.<br>- `timeouts` block<br><br> ---<br> `timeouts` block supports the following:<br> - `create` - (Defaults to 30 minutes) Used when creating the Storage Container.<br> - `delete` - (Defaults to 30 minutes) Used when deleting the Storage Container.<br> - `read` - (Defaults to 5 minutes) Used when retrieving the Storage Container.<br> - `update` - (Defaults to 30 minutes) Used when updating the Storage Container. | <pre>list(object({<br>    container_access_type = optional(string)<br>    metadata              = optional(map(string))<br>    name                  = string<br>    blob = optional(list(object({<br>      name           = string<br>      type           = string<br>      size           = optional(number, 0)<br>      access_tier    = optional(string)<br>      cache_control  = optional(string)<br>      content_type   = optional(string)<br>      content_md5    = optional(string)<br>      source         = optional(string)<br>      source_content = optional(string)<br>      source_uri     = optional(string)<br>      parallelism    = optional(number)<br>      metadata       = optional(map(string), {})<br>      timeouts = optional(object({<br>        create = optional(string)<br>        delete = optional(string)<br>        read   = optional(string)<br>        update = optional(string)<br>      }))<br>    })))<br>    timeouts = optional(object({<br>      create = optional(string)<br>      delete = optional(string)<br>      read   = optional(string)<br>      update = optional(string)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_storage_queue"></a> [storage\_queue](#input\_storage\_queue) | - `metadata` - (Optional) A mapping of MetaData which should be assigned to this Storage Queue.<br>- `name` - (Required) The name of the Queue which should be created within the Storage Account. Must be unique within the storage account the queue is located. Changing this forces a new resource to be created.<br><br>---<br>`timeouts` block supports the following:<br>- `create` - (Defaults to 30 minutes) Used when creating the Storage Queue.<br>- `delete` - (Defaults to 30 minutes) Used when deleting the Storage Queue.<br>- `read` - (Defaults to 5 minutes) Used when retrieving the Storage Queue.<br>- `update` - (Defaults to 30 minutes) Used when updating the Storage Queue. | <pre>list(object({<br>    metadata = optional(map(string))<br>    name     = string<br>    timeouts = optional(object({<br>      create = optional(string)<br>      delete = optional(string)<br>      read   = optional(string)<br>      update = optional(string)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_storage_share"></a> [storage\_share](#input\_storage\_share) | - `access_tier` - (Optional) The access tier of the File Share. Possible values are `Hot`, `Cool` and `TransactionOptimized`, `Premium`.<br> - `enabled_protocol` - (Optional) The protocol used for the share. Possible values are `SMB` and `NFS`. The `SMB` indicates the share can be accessed by SMBv3.0, SMBv2.1 and REST. The `NFS` indicates the share can be accessed by NFSv4.1. Defaults to `SMB`. Changing this forces a new resource to be created.<br> - `metadata` - (Optional) A mapping of MetaData for this File Share.<br> - `name` - (Required) The name of the share. Must be unique within the storage account where the share is located. Changing this forces a new resource to be created.<br> - `quota` - (Required) The maximum size of the share, in gigabytes. For Standard storage accounts, this must be `1`GB (or higher) and at most `5120` GB (`5` TB). For Premium FileStorage storage accounts, this must be greater than 100 GB and at most `102400` GB (`100` TB).<br><br>---<br>`directories` block supports the following:<br>- `name` - (Required) The name (or path) of the Directory that should be created within this File Share. Changing this forces a new resource to be created.<br>- `files` block<br><br>---<br>`files` block supports the following:<br>- `name` - (Required) The name (or path) of the File that should be created within this File Share. Changing this forces a new resource to be created.<br>- `source` - (Optional) An absolute path to a file on the local system. Changing this forces a new resource to be created.<br>- `content_type` - (Optional) The content type of the share file. Defaults to application/octet-stream. Some possible values are `text/plain`, `application/json`, `application/ms-excel`, `image/png`, `audio/mpeg`, `video/mp4`, etc.<br>- `content_md5` - (Optional) The MD5 sum of the file contents. Changing this forces a new resource to be created.<br>- `content_encoding` - (Optional) Specifies which content encodings have been applied to the file. Some possible values are `gzip`, `deflate`, `identity`, `compress`, etc.<br>- `content_disposition` - (Optional) Sets the file’s Content-Disposition header. Some possible values are `inline`, `attachment`, `filename=example.txt`, etc.<br>- `metadata` - (Optional) A mapping of metadata to assign to this file.<br><br> ---<br> `acl` block supports the following:<br> - `id` - (Required) The ID which should be used for this Shared Identifier.<br><br> ---<br> `access_policy` block supports the following:<br> - `expiry` - (Optional) The time at which this Access Policy should be valid until, in [ISO8601](https://en.wikipedia.org/wiki/ISO_8601) format.<br> - `permissions` - (Required) The permissions which should be associated with this Shared Identifier. Possible value is combination of `r` (read), `w` (write), `d` (delete), and `l` (list).<br> - `start` - (Optional) The time at which this Access Policy should be valid from, in [ISO8601](https://en.wikipedia.org/wiki/ISO_8601) format.<br><br> ---<br> `timeouts` block supports the following:<br> - `create` - (Defaults to 30 minutes) Used when creating the Storage Share.<br> - `delete` - (Defaults to 30 minutes) Used when deleting the Storage Share.<br> - `read` - (Defaults to 5 minutes) Used when retrieving the Storage Share.<br> - `update` - (Defaults to 30 minutes) Used when updating the Storage Share. | <pre>list(object({<br>    access_tier      = optional(string)<br>    enabled_protocol = optional(string)<br>    metadata         = optional(map(string))<br>    name             = string<br>    quota            = number<br>    directories = optional(list(object({<br>      name = string<br>      files = optional(list(object({<br>        name                = string<br>        source              = optional(string)<br>        content_type        = optional(string)<br>        content_md5         = optional(string)<br>        content_encoding    = optional(string)<br>        content_disposition = optional(string)<br>        metadata            = optional(map(string))<br>        timeouts = optional(object({<br>          create = optional(string)<br>          delete = optional(string)<br>          read   = optional(string)<br>          update = optional(string)<br>        }))<br>      })))<br>      metadata = optional(map(string), {})<br>      timeouts = optional(object({<br>        create = optional(string)<br>        delete = optional(string)<br>        read   = optional(string)<br>        update = optional(string)<br>      }))<br>    })))<br>    acl = optional(set(object({<br>      id = string<br>      access_policy = optional(list(object({<br>        expiry      = optional(string)<br>        permissions = string<br>        start       = optional(string)<br>      })))<br>    })))<br>    timeouts = optional(object({<br>      create = optional(string)<br>      delete = optional(string)<br>      read   = optional(string)<br>      update = optional(string)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_storage_table"></a> [storage\_table](#input\_storage\_table) | - `name` - (Required) The name of the storage table. Only Alphanumeric characters allowed, starting with a letter. Must be unique within the storage account the table is located. Changing this forces a new resource to be created.<br><br>---<br>`entities` block supports the following:<br>- `partition_key` - (Required) The key for the partition where the entity will be retrieved.<br>- `row_key` - (Required) The key for the row where the entity will be inserted/merged. Changing this forces a new resource.<br>- `entity` - (Required) A map of key/value pairs that describe the entity to be inserted/merged in to the storage table.<br><br> ---<br> `acl` block supports the following:<br> - `id` - (Required) The ID which should be used for this Shared Identifier.<br><br> ---<br> `access_policy` block supports the following:<br> - `expiry` - (Required) The ISO8061 UTC time at which this Access Policy should be valid until.<br> - `permissions` - (Required) The permissions which should associated with this Shared Identifier.<br> - `start` - (Required) The ISO8061 UTC time at which this Access Policy should be valid from.<br> - `utc_offset` - (Optional) The difference in hours and minutes between Coordinated Universal Time and local solar time. Defaults to Central Time Zone utc offset of "-6h".<br><br> ---<br> `timeouts` block supports the following:<br> - `create` - (Defaults to 30 minutes) Used when creating the Storage Table.<br> - `delete` - (Defaults to 30 minutes) Used when deleting the Storage Table.<br> - `read` - (Defaults to 5 minutes) Used when retrieving the Storage Table.<br> - `update` - (Defaults to 30 minutes) Used when updating the Storage Table. | <pre>list(object({<br>    name = string<br>    entities = optional(map(object({<br>      partition_key = string<br>      row_key       = string<br>      entity        = map(string)<br>    })))<br>    acl = optional(set(object({<br>      id = string<br>      access_policy = optional(list(object({<br>        expiry      = string<br>        permissions = string<br>        start       = string<br>        utc_offset  = optional(string, "-6h")<br>      })))<br>    })))<br>    timeouts = optional(object({<br>      create = optional(string)<br>      delete = optional(string)<br>      read   = optional(string)<br>      update = optional(string)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_table_encryption_key_type"></a> [table\_encryption\_key\_type](#input\_table\_encryption\_key\_type) | (Optional) The encryption type of the table service. Possible values are `Service` and `Account`. Changing this forces a new resource to be created. Default value is `Service`. | `string` | `"Service"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the resource. | `map(string)` | `null` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | - `create` - (Defaults to 60 minutes) Used when creating the Storage Account.<br>- `delete` - (Defaults to 60 minutes) Used when deleting the Storage Account.<br>- `read` - (Defaults to 5 minutes) Used when retrieving the Storage Account.<br>- `update` - (Defaults to 60 minutes) Used when updating the Storage Account. | <pre>object({<br>    create = optional(string)<br>    delete = optional(string)<br>    read   = optional(string)<br>    update = optional(string)<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | Fqdns for storage services. |
| <a name="output_local_user"></a> [local\_user](#output\_local\_user) | Storage Account Local User. |
| <a name="output_management_locks"></a> [management\_locks](#output\_management\_locks) | Map of the management locks created |
| <a name="output_management_policy_id"></a> [management\_policy\_id](#output\_management\_policy\_id) | ID of the management policy created |
| <a name="output_primary_access_key"></a> [primary\_access\_key](#output\_primary\_access\_key) | The primary access key for the storage account |
| <a name="output_primary_blob_connection_string"></a> [primary\_blob\_connection\_string](#output\_primary\_blob\_connection\_string) | The connection string associated with the primary blob location. |
| <a name="output_primary_blob_endpoint"></a> [primary\_blob\_endpoint](#output\_primary\_blob\_endpoint) | The endpoint URL for blob storage in the primary location. |
| <a name="output_primary_blob_host"></a> [primary\_blob\_host](#output\_primary\_blob\_host) | The hostname with port if applicable for blob storage in the primary location. |
| <a name="output_primary_blob_microsoft_endpoint"></a> [primary\_blob\_microsoft\_endpoint](#output\_primary\_blob\_microsoft\_endpoint) | The microsoft routing endpoint URL for blob storage in the primary location. |
| <a name="output_primary_blob_microsoft_host"></a> [primary\_blob\_microsoft\_host](#output\_primary\_blob\_microsoft\_host) | The microsoft routing hostname with port if applicable for blob storage in the primary location. |
| <a name="output_primary_connection_string"></a> [primary\_connection\_string](#output\_primary\_connection\_string) | The primary connection string for the storage account |
| <a name="output_primary_dfs_endpoint"></a> [primary\_dfs\_endpoint](#output\_primary\_dfs\_endpoint) | The endpoint URL for dfs storage in the primary location. |
| <a name="output_primary_dfs_host"></a> [primary\_dfs\_host](#output\_primary\_dfs\_host) | The hostname with port if applicable for dfs storage in the primary location. |
| <a name="output_primary_dfs_microsoft_endpoint"></a> [primary\_dfs\_microsoft\_endpoint](#output\_primary\_dfs\_microsoft\_endpoint) | The microsoft routing endpoint URL for dfs storage in the primary location. |
| <a name="output_primary_dfs_microsoft_host"></a> [primary\_dfs\_microsoft\_host](#output\_primary\_dfs\_microsoft\_host) | The microsoft routing hostname with port if applicable for dfs storage in the primary location. |
| <a name="output_primary_file_endpoint"></a> [primary\_file\_endpoint](#output\_primary\_file\_endpoint) | The endpoint URL for file storage in the primary location. |
| <a name="output_primary_file_host"></a> [primary\_file\_host](#output\_primary\_file\_host) | The hostname with port if applicable for file storage in the primary location. |
| <a name="output_primary_file_microsoft_endpoint"></a> [primary\_file\_microsoft\_endpoint](#output\_primary\_file\_microsoft\_endpoint) | The microsoft routing endpoint URL for file storage in the primary location. |
| <a name="output_primary_file_microsoft_host"></a> [primary\_file\_microsoft\_host](#output\_primary\_file\_microsoft\_host) | The microsoft routing hostname with port if applicable for file storage in the primary location. |
| <a name="output_primary_location"></a> [primary\_location](#output\_primary\_location) | The primary location of the storage account. |
| <a name="output_primary_queue_endpoint"></a> [primary\_queue\_endpoint](#output\_primary\_queue\_endpoint) | The endpoint URL for queue storage in the primary location. |
| <a name="output_primary_queue_host"></a> [primary\_queue\_host](#output\_primary\_queue\_host) | The hostname with port if applicable for queue storage in the primary location. |
| <a name="output_primary_queue_microsoft_endpoint"></a> [primary\_queue\_microsoft\_endpoint](#output\_primary\_queue\_microsoft\_endpoint) | The microsoft endpoint URL for queue storage in the primary location. |
| <a name="output_primary_queue_microsoft_host"></a> [primary\_queue\_microsoft\_host](#output\_primary\_queue\_microsoft\_host) | The microsoft hostname with port if applicable for queue storage in the primary location. |
| <a name="output_primary_table_endpoint"></a> [primary\_table\_endpoint](#output\_primary\_table\_endpoint) | The endpoint with port if applicable for table storage in the primary location. |
| <a name="output_primary_table_host"></a> [primary\_table\_host](#output\_primary\_table\_host) | The hostname with port if applicable for table storage in the primary location. |
| <a name="output_primary_table_microsoft_endpoint"></a> [primary\_table\_microsoft\_endpoint](#output\_primary\_table\_microsoft\_endpoint) | The endpoint with port if applicable for table storage in the primary location. |
| <a name="output_primary_table_microsoft_host"></a> [primary\_table\_microsoft\_host](#output\_primary\_table\_microsoft\_host) | The hostname with port if applicable for table storage in the primary location. |
| <a name="output_primary_web_endpoint"></a> [primary\_web\_endpoint](#output\_primary\_web\_endpoint) | The endpoint with port if applicable for web storage in the primary location. |
| <a name="output_primary_web_host"></a> [primary\_web\_host](#output\_primary\_web\_host) | The hostname with port if applicable for web storage in the primary location. |
| <a name="output_primary_web_microsoft_endpoint"></a> [primary\_web\_microsoft\_endpoint](#output\_primary\_web\_microsoft\_endpoint) | The endpoint with port if applicable for web storage in the primary location. |
| <a name="output_primary_web_microsoft_host"></a> [primary\_web\_microsoft\_host](#output\_primary\_web\_microsoft\_host) | The hostname with port if applicable for web storage in the primary location. |
| <a name="output_private_endpoint_blob"></a> [private\_endpoint\_blob](#output\_private\_endpoint\_blob) | Blob Private Endpoint |
| <a name="output_private_endpoint_dfs"></a> [private\_endpoint\_dfs](#output\_private\_endpoint\_dfs) | Blob Private Endpoint |
| <a name="output_private_endpoint_file"></a> [private\_endpoint\_file](#output\_private\_endpoint\_file) | File Private Endpoint |
| <a name="output_private_endpoint_queue"></a> [private\_endpoint\_queue](#output\_private\_endpoint\_queue) | Queue Private Endpoint |
| <a name="output_private_endpoint_table"></a> [private\_endpoint\_table](#output\_private\_endpoint\_table) | Table Private Endpoint |
| <a name="output_private_endpoint_web"></a> [private\_endpoint\_web](#output\_private\_endpoint\_web) | Blob Private Endpoint |
| <a name="output_secondary_access_key"></a> [secondary\_access\_key](#output\_secondary\_access\_key) | The primary access key for the storage account. |
| <a name="output_secondary_blob_connection_string"></a> [secondary\_blob\_connection\_string](#output\_secondary\_blob\_connection\_string) | The connection string associated with the secondary blob location. |
| <a name="output_secondary_blob_endpoint"></a> [secondary\_blob\_endpoint](#output\_secondary\_blob\_endpoint) | The endpoint URL for blob storage in the secondary location. |
| <a name="output_secondary_blob_host"></a> [secondary\_blob\_host](#output\_secondary\_blob\_host) | The hostname with port if applicable for blob storage in the secondary location. |
| <a name="output_secondary_blob_microsoft_endpoint"></a> [secondary\_blob\_microsoft\_endpoint](#output\_secondary\_blob\_microsoft\_endpoint) | The microsoft routing endpoint URL for blob storage in the secondary location. |
| <a name="output_secondary_blob_microsoft_host"></a> [secondary\_blob\_microsoft\_host](#output\_secondary\_blob\_microsoft\_host) | The microsoft routing hostname with port if applicable for blob storage in the secondary location. |
| <a name="output_secondary_connection_string"></a> [secondary\_connection\_string](#output\_secondary\_connection\_string) | The secondary connection string for the storage account |
| <a name="output_secondary_dfs_endpoint"></a> [secondary\_dfs\_endpoint](#output\_secondary\_dfs\_endpoint) | The endpoint URL for dfs storage in the secondary location. |
| <a name="output_secondary_dfs_host"></a> [secondary\_dfs\_host](#output\_secondary\_dfs\_host) | The hostname with port if applicable for dfs storage in the secondary location. |
| <a name="output_secondary_dfs_microsoft_endpoint"></a> [secondary\_dfs\_microsoft\_endpoint](#output\_secondary\_dfs\_microsoft\_endpoint) | The microsoft routing endpoint URL for dfs storage in the secondary location. |
| <a name="output_secondary_dfs_microsoft_host"></a> [secondary\_dfs\_microsoft\_host](#output\_secondary\_dfs\_microsoft\_host) | The microsoft routing hostname with port if applicable for dfs storage in the secondary location. |
| <a name="output_secondary_file_endpoint"></a> [secondary\_file\_endpoint](#output\_secondary\_file\_endpoint) | The endpoint URL for file storage in the secondary location. |
| <a name="output_secondary_file_host"></a> [secondary\_file\_host](#output\_secondary\_file\_host) | The hostname with port if applicable for file storage in the secondary location. |
| <a name="output_secondary_file_microsoft_endpoint"></a> [secondary\_file\_microsoft\_endpoint](#output\_secondary\_file\_microsoft\_endpoint) | The microsoft routing endpoint URL for file storage in the secondary location. |
| <a name="output_secondary_file_microsoft_host"></a> [secondary\_file\_microsoft\_host](#output\_secondary\_file\_microsoft\_host) | The microsoft routing hostname with port if applicable for file storage in the secondary location. |
| <a name="output_secondary_location"></a> [secondary\_location](#output\_secondary\_location) | The secondary location of the storage account. |
| <a name="output_secondary_queue_endpoint"></a> [secondary\_queue\_endpoint](#output\_secondary\_queue\_endpoint) | The endpoint URL for queue storage in the secondary location. |
| <a name="output_secondary_queue_host"></a> [secondary\_queue\_host](#output\_secondary\_queue\_host) | The hostname with port if applicable for queue storage in the secondary location. |
| <a name="output_secondary_queue_microsoft_endpoint"></a> [secondary\_queue\_microsoft\_endpoint](#output\_secondary\_queue\_microsoft\_endpoint) | The microsoft  endpoint URL for queue storage in the secondary location. |
| <a name="output_secondary_queue_microsoft_host"></a> [secondary\_queue\_microsoft\_host](#output\_secondary\_queue\_microsoft\_host) | The microsoft hostname with port if applicable for queue storage in the secondary location. |
| <a name="output_secondary_table_endpoint"></a> [secondary\_table\_endpoint](#output\_secondary\_table\_endpoint) | The endpoint with port if applicable for table storage in the secondary location. |
| <a name="output_secondary_table_host"></a> [secondary\_table\_host](#output\_secondary\_table\_host) | The hostname with port if applicable for table storage in the secondary location. |
| <a name="output_secondary_table_microsoft_endpoint"></a> [secondary\_table\_microsoft\_endpoint](#output\_secondary\_table\_microsoft\_endpoint) | The microsoft endpoint with port if applicable for table storage in the secondary location. |
| <a name="output_secondary_table_microsoft_host"></a> [secondary\_table\_microsoft\_host](#output\_secondary\_table\_microsoft\_host) | The microsoft hostname with port if applicable for table storage in the secondary location. |
| <a name="output_secondary_web_endpoint"></a> [secondary\_web\_endpoint](#output\_secondary\_web\_endpoint) | The endpoint with port if applicable for web storage in the secondary location. |
| <a name="output_secondary_web_host"></a> [secondary\_web\_host](#output\_secondary\_web\_host) | The hostname with port if applicable for web storage in the secondary location. |
| <a name="output_secondary_web_microsoft_endpoint"></a> [secondary\_web\_microsoft\_endpoint](#output\_secondary\_web\_microsoft\_endpoint) | The microsoft endpoint with port if applicable for web storage in the secondary location. |
| <a name="output_secondary_web_microsoft_host"></a> [secondary\_web\_microsoft\_host](#output\_secondary\_web\_microsoft\_host) | The microsoft hostname with port if applicable for web storage in the secondary location. |
| <a name="output_storage_account"></a> [storage\_account](#output\_storage\_account) | The Storage Account object. |
| <a name="output_storage_account_access_tier"></a> [storage\_account\_access\_tier](#output\_storage\_account\_access\_tier) | The access tier of the Storage Account. |
| <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id) | The ID of the Storage Account. |
| <a name="output_storage_account_kind"></a> [storage\_account\_kind](#output\_storage\_account\_kind) | The kind of the Storage Account. |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | The name of the storage account |
| <a name="output_storage_account_nonsensitive"></a> [storage\_account\_nonsensitive](#output\_storage\_account\_nonsensitive) | Nonsensitive outputs of the Storage Account object. |
| <a name="output_storage_account_replication_type"></a> [storage\_account\_replication\_type](#output\_storage\_account\_replication\_type) | The account replication type of the Storage Account. |
| <a name="output_storage_account_tier"></a> [storage\_account\_tier](#output\_storage\_account\_tier) | The tier of the Storage Account. |
| <a name="output_storage_blob"></a> [storage\_blob](#output\_storage\_blob) | Map of storage blob created. |
| <a name="output_storage_blob_inventory_policy"></a> [storage\_blob\_inventory\_policy](#output\_storage\_blob\_inventory\_policy) | Id of the storage blob inventory policy created. |
| <a name="output_storage_container"></a> [storage\_container](#output\_storage\_container) | Map of storage containers created. |
| <a name="output_storage_data_lake_gen2_filesystem"></a> [storage\_data\_lake\_gen2\_filesystem](#output\_storage\_data\_lake\_gen2\_filesystem) | Map of storage data lake gen2 filesystem created. |
| <a name="output_storage_data_lake_gen2_path"></a> [storage\_data\_lake\_gen2\_path](#output\_storage\_data\_lake\_gen2\_path) | Map of storage data lake gen2 path created. |
| <a name="output_storage_queue"></a> [storage\_queue](#output\_storage\_queue) | Map of storage queues created. |
| <a name="output_storage_share"></a> [storage\_share](#output\_storage\_share) | Map of storage shares created. |
| <a name="output_storage_share_directory"></a> [storage\_share\_directory](#output\_storage\_share\_directory) | Map of storage share directories created. |
| <a name="output_storage_share_file"></a> [storage\_share\_file](#output\_storage\_share\_file) | Map of storage share directories created. |
| <a name="output_storage_table"></a> [storage\_table](#output\_storage\_table) | Map of storage tables created. |
| <a name="output_storage_table_entity"></a> [storage\_table\_entity](#output\_storage\_table\_entity) | Map of storage table entities created. |
<!-- END_TF_DOCS -->