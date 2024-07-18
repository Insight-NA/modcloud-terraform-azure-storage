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
  source = "../../"

  tags                = local.tags
  resource_group_name = var.resource_group_name

  storage_queue = [
    {
      name = "queue-first"
      metadata = {
        testkey        = "testvalue"
        queuetype      = module.azure_storage_queue.storage_account_tier
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