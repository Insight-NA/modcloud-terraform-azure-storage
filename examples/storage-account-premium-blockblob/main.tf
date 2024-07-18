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

module "azure_storage_account_premium_blockblob" {
  source                   = "../../"
  tags                = local.tags
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
