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
