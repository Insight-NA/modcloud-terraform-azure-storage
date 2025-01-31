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
  source                   = "../../"
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