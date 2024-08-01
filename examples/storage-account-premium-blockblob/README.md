- [How to Use this Module](#how-to-use-this-module)
- [Azure Storage Redundency](#azure-storage-redundency)
- [Premium block blob storage accounts](#premium-block-blob-storage-accounts)
- [Azure Data Lake Storage Gen2](#azure-data-lake-storage-gen2)

## How to Use this Module

```hcl
locals {
  tags = {
    env            = "dev"
    app_code       = "storage"
    app_instance   = "blockblob"
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

module "azure_storage_account_premium_blockblob" {
  source                   = "../../"
  tags                     = local.tags
  storage_account_name     = substr(format("st%s%s%s%s", local.tags.app_code, local.tags.env, local.tags.app_instance, random_id.random_suffix.hex), 0, 24)
  resource_group_name      = var.resource_group_name
  account_kind             = "BlockBlobStorage"
  account_replication_type = "ZRS"
  access_tier              = "Hot"
  is_hns_enabled           = "true"

  data_lake_gen2 = [

    {
      name = "example-data-lake-gen2-filesystem"
      directory = [
        {
          path = "example-data-lake-gen2-path"
        }
      ]
    }
  ]
}
```

## Azure Storage Redundency

To check the requirements for storage account skus or types of redundency please refer to the [azure documentation](https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy?toc=%2Fazure%2Fstorage%2Fblobs%2Ftoc.json&bc=%2Fazure%2Fstorage%2Fblobs%2Fbreadcrumb%2Ftoc.json#summary-of-redundancy-options).  

Some skus or redundency types are not available in all regions. 

## Premium block blob storage accounts

To learn more about premiumn block blob storage accounts please refer to the [azure documentation](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-block-blob-premium).

## Azure Data Lake Storage Gen2

Azure Data Lake Storage Gen2 is a set of capabilities dedicated to big data analytics, built on Azure Blob Storage. Data Lake Storage Gen2 provides file system semantics, file-level security, and scale. Because these capabilities are built on Blob storage, you also get low-cost, tiered storage, with high availability/disaster recovery capabilities. To learn more about data lake storage gen2, please refer to the [azure documentation](https://learn.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction)