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

  tfc_ip_ranges = [
    "52.86.200.106", "52.86.201.227", "52.70.186.109",
    "44.236.246.186", "54.185.161.84", "44.238.78.236",
    "75.2.98.97", "99.83.150.238"
  ]
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
  source               = "../../"
  tags                 = local.tags
  storage_account_name = substr(format("st%s%s%s%s", local.tags.app_code, local.tags.env, local.tags.app_instance, random_id.random_suffix.hex), 0, 24)
  resource_group_name  = var.resource_group_name

  management_locks = {
    CanNotDelete = false
    ReadOnly     = false
  }

  network_rules = {
    default_action = "Deny"
    # This could be a specific ip address for individual users, e.g., 20.94.5.238
    # or an ip range for a group of users (VPN), e.g., 20.128.0.0/16
    ip_rules                   = concat(local.tfc_ip_ranges, ["20.94.5.238"])
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