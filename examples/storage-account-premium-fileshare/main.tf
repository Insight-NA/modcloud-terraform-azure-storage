module "tagging" {
  source  = "app.terraform.io/hca-healthcare/tagging/hca"
  version = "~> 0.2"

  app_environment = "prod"
  app_code        = "tst"
  app_instance    = "tbd"
  classification  = "internal-only"
  cost_id         = "12345"
  department_id   = "678901"
  project_id      = "it-ab00c123"
  tco_id          = "abc"
  sc_group        = "corp-infra-cloud-platform"
}

module "azure_storage_fileshare_premium" {
  source                   = "../../"
  tags                     = module.tagging.labels
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