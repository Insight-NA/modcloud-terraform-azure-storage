locals {
  tags = {
    env            = "dev"
    app_code       = "storage"
    app_instance   = "table"
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

module "azure_storage_table" {
  source               = "../../"
  tags                 = local.tags
  storage_account_name = substr(format("st%s%s%s%s", local.tags.app_code, local.tags.env, local.tags.app_instance, random_id.random_suffix.hex), 0, 24)
  resource_group_name  = var.resource_group_name

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
}
