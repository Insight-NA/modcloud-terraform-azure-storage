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
    managed_by     = "terraform"
  }
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