- [How to Use this Module](#how-to-use-this-module)
- [Azure Storage Redundency](#azure-storage-redundency)
- [Azure File Share Storage](#azure-file-share-storage)

## How to Use this Module

This example will create a storage account with two fileshares. The only required portion is the name and quota attributes under storage_storage, and the account replication type must be either 'LRS' or 'ZRS'. If a different account replication type is a must, use account kind 'StorageV2' and account tier 'Standard'. Storage accounts of the kind 'FileStorage' are of the account tier 'Premium'.

NOTE: Fileshares of the 'NFS' protocol are not supported at this time. The NFS protocol does not support encryption and relies on network-level security, however HCA policy requires enable_https_traffic_only be set to true.

CAUTION: Nested fileshare directories are not possible at this time due to potential dependencies, and resource creation & destroy ordering. 

```hcl
locals {
  tags = {
    env            = "dev"
    app_code       = "storage"
    app_instance   = "fileshare"
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

module "azure_storage_fileshare_premium" {
  source  = "app.terraform.io/insight/azure-storage/terraform"
  version = "1.0.0"
  
  tags                     = local.tags
  storage_account_name     = substr(format("st%s%s%s%s", local.tags.app_code, local.tags.env, local.tags.app_instance, random_id.random_suffix.hex), 0, 24)
  resource_group_name      = var.resource_group_name
  account_kind             = "FileStorage"
  account_replication_type = "ZRS"

  storage_share = [
    {
      name  = "first-share"
      quota = 101
    },
    {
      name  = "second-share"
      quota = 100
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
    cors_rule = [
      {
        allowed_headers    = ["x-ms-meta-data*", "x-ms-meta-target*"]
        allowed_methods    = ["PUT", "GET"]
        allowed_origins    = ["http://*.contoso.com", "http://www.fabrikam.com"]
        exposed_headers    = ["x-ms-meta-*"]
        max_age_in_seconds = 200
      }
    ]
    retention_policy = {
      days = 8
    }
    smb = {
      versions                        = ["SMB3.1.1"]
      authentication_types            = ["Kerberos"]
      kerberos_ticket_encryption_type = ["AES-256"]
      channel_encryption_type         = ["AES-256-GCM"]
      multichannel_enabled            = true
    }
  }
}
```

## Azure Storage Redundency

To check the requirements for storage account skus or types of redundency please refer to the [azure documentation](https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy?toc=%2Fazure%2Fstorage%2Fblobs%2Ftoc.json&bc=%2Fazure%2Fstorage%2Fblobs%2Fbreadcrumb%2Ftoc.json#summary-of-redundancy-options).  

Some skus or redundency types are not available in all regions. 

## Azure File Share Storage

To learn more about Azure file share storage, please refere to [azure documentation](https://learn.microsoft.com/en-us/azure/storage/files/storage-files-introduction). Further details on SMB Azure file shares can be found [here](https://learn.microsoft.com/en-us/azure/storage/files/storage-how-to-create-file-share?tabs=azure-portal).