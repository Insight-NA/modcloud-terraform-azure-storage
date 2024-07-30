- [How to Use this Module](#how-to-use-this-module)
- [Azure Blob Storage](#azure-blob-storage)
- [Cache Control](#cache-control)
- [Azure Storage Blob Inventory](#azure-storage-blob-inventory)
- [Azure Storage Lifecycle Management Policy](#azure-storage-lifecycle-management-policy)
- [Azure Storage Blob Data Index Tags](#azure-storage-blob-data-index-tags)
- [Azure Storage Redundency](#azure-storage-redundency)

## How to Use this Module

```hcl
locals {
  tags = {
    env            = "dev"
    app_code       = "storage"
    app_instance   = "blob"
    classification = "internal-only"
    cost_id        = "12345"
    department_id  = "678901"
    project_id     = "it-ab00c123"
    org_code       = "insight"
    managed_by      = "terraform"
  }

  tfc_ip_ranges = [
    "52.86.200.106", "52.86.201.227", "52.70.186.109",
    "44.236.246.186", "54.185.161.84", "44.238.78.236",
    "75.2.98.97", "99.83.150.238"
  ]
}

resource "random_id" "random_suffix" {
  byte_length = 8
}

module "azure_storage_standard_blob" {
  source                   = "../../"
  tags                     = local.tags
  storage_account_name     = substr(format("st%s%s%s%s", local.tags.app_code, local.tags.env, local.tags.app_instance, random_id.random_suffix.hex), 0, 24)
  resource_group_name      = var.resource_group_name
  account_replication_type = "LRS"

  network_rules = {
    # This could be a specific ip address for individual users, e.g., 20.94.5.238
    # or an ip range for a group of users (VPN), e.g., 20.128.0.0/16
    ip_rules = concat(local.tfc_ip_ranges, ["20.94.5.238"])
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
}
```
## Azure Blob Storage

Azure Blob Storage is Microsoft's object storage solution for the cloud. Blob Storage is optimized for storing massive amounts of unstructured data. Unstructured data is data that doesn't adhere to a particular data model or definition, such as text or binary data. To learn more about Azure blob storage, please refere to the [Azure documentation](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction)

## Cache Control

To learn more about the cache control header content of the response, in regards to blob configuration, please refere to the [MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)

## Azure Storage Blob Inventory

Azure Storage blob inventory provides a list of the containers, blobs, blob versions, and snapshots in your storage account, along with their associated properties. It generates an output report in either comma-separated values (CSV) or Apache Parquet format on a daily or weekly basis. You can use the report to audit retention, legal hold or encryption status of your storage account contents, or you can use it to understand the total data size, age, tier distribution, or other attributes of your data. Blob inventory rules allow you to filter the contents of the report by blob type, prefix, or by selecting the blob properties to include in the report. For further details about the Azure storage blob inventory please refer to the [Azure documentation](https://learn.microsoft.com/en-us/azure/storage/blobs/blob-inventory)

## Azure Storage Lifecycle Management Policy
Azure Storage lifecycle management offers a rule-based policy that you can use to transition blob data to the appropriate access tiers or to expire data at the end of the data lifecycle. A lifecycle policy acts on a base blob, and optionally on the blob's versions or snapshots. For more information about lifecycle management policies, see the [Azure documentation](https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-policy-configure?tabs=azure-portal).

## Azure Storage Blob Data Index Tags
As datasets get larger, finding a specific object in a sea of data can be difficult. Blob index tags provide data management and discovery capabilities by using key-value index tag attributes. You can categorize and find objects within a single container or across all containers in your storage account. As data requirements change, objects can be dynamically categorized by updating their index tags. Objects can remain in-place with their current container organization. For more inforation see the [Azure documentation](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-manage-find-blobs?tabs=azure-portal).

## Azure Storage Redundency

To check the requirements for storage account skus or types of redundency please refer to the [Azure documentation](https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy?toc=%2Fazure%2Fstorage%2Fblobs%2Ftoc.json&bc=%2Fazure%2Fstorage%2Fblobs%2Fbreadcrumb%2Ftoc.json#summary-of-redundancy-options).  

Some skus or redundency types are not available in all regions. 