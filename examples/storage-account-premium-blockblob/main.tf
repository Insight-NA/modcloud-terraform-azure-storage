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

  tfc_ip_ranges = [
    "52.86.200.106", "52.86.201.227", "52.70.186.109",
    "44.236.246.186", "54.185.161.84", "44.238.78.236",
    "75.2.98.97", "99.83.150.238"
  ]
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

  network_rules = {
    # This could be a specific ip address for individual users, e.g., 20.94.5.238
    # or an ip range for a group of users (VPN), e.g., 20.128.0.0/16
    ip_rules = concat(local.tfc_ip_ranges, ["20.94.5.238"])
  }

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
