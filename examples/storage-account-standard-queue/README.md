- [How to Use this Module](#how-to-use-this-module)
- [Azure Queue Storage](#azure-queue-storage)
- [Azure Storage Redundency](#azure-storage-redundency)
- [Cross-Origin Resource Sharing (CORS) support for Azure Storage](#cross-origin-resource-sharing-cors-support-for-azure-storage)

## How to Use this Module

This example will create a storage account with two queues. The only required portion is the name attribute under storage_queue. Currently defaults to Standard StorageV2 with Read-Access Geo-Redunant replication. The optional queue_properties show an example of additional configuration settings that are available.

```hcl
locals {
  tags = {
    env            = "prod"
    app_code       = "tst"
    app_instance   = "tbd"
    classification = "internal-only"
    cost_id        = "12345"
    department_id  = "678901"
    project_id     = "it-ab00c123"
  }
}

module "azure_storage_queue" {
  source                  = "app.terraform.io/hca-healthcare/storageaccount/azure"
  version                 = "~>4.2.0"

  tags                = local.tags
  resource_group_name      = var.resource_group_name

  storage_queue = [
    { 
      name = "queue-first"
      metadata = {
        testkey = "testvalue"
        queuetype = module.azure_storage_queue.storage_account_tier
        classification = module.tagging.labels.classification
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
}
```

## Azure Queue Storage

Azure Queue Storage is a service for storing large numbers of messages. You access messages from anywhere in the world via authenticated calls using HTTP or HTTPS. A queue message can be up to 64 KB in size. A queue may contain millions of messages, up to the total capacity limit of a storage account. To learn more about Azure queue storage, please refer to the [azure documentation](https://learn.microsoft.com/en-us/azure/storage/queues/storage-queues-introduction).


## Azure Storage Redundency

To check the requirements for storage account skus or types of redundency please refer to the [azure documentation](https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy?toc=%2Fazure%2Fstorage%2Fblobs%2Ftoc.json&bc=%2Fazure%2Fstorage%2Fblobs%2Fbreadcrumb%2Ftoc.json#summary-of-redundancy-options).  

Some skus or redundency types are not available in all regions. 

## Cross-Origin Resource Sharing (CORS) support for Azure Storage

CORS is an HTTP feature that enables a web application running under one domain to access resources in another domain. Web browsers implement a security restriction known as same-origin policy that prevents a web page from calling APIs in a different domain; CORS provides a secure way to allow one domain (the origin domain) to call APIs in another domain. To learn more please refer to the [azure documentation](https://learn.microsoft.com/en-us/rest/api/storageservices/cross-origin-resource-sharing--cors--support-for-the-azure-storage-services)