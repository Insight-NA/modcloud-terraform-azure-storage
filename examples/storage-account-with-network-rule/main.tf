locals {
  tags = {
    env            = "dev"
    app_code       = "storage"
    app_instance   = "network"
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

  private_dns_zones = toset([
    "privatelink.blob.core.windows.net",
    "privatelink.table.core.windows.net",
    "privatelink.queue.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.web.core.windows.net",
    "privatelink.dfs.core.windows.net"
  ])

  private_dns_zone_map = {
    for zone_name, zone in azurerm_private_dns_zone.this : zone_name => {
      name = zone.name
      id   = zone.id
    }
  }
}

data "azurerm_subnet" "default" {
  name                 = "default"
  virtual_network_name = "module-testing-vnet"
  resource_group_name  = var.resource_group_name
}

data "azurerm_subnet" "private_endpoint" {
  name                 = "private_endpoint"
  virtual_network_name = "module-testing-vnet"
  resource_group_name  = var.resource_group_name
}

resource "random_id" "random_suffix" {
  byte_length = 8
}

resource "azurerm_network_security_group" "default" {
  name                = "nsg-default"
  location            = "eastus"
  resource_group_name = var.resource_group_name

  security_rule {
    # Inbound NSG Rules
    access                       = "Deny"
    destination_address_prefix   = "*"
    destination_address_prefixes = null
    destination_port_range       = null
    destination_port_ranges      = ["0-65535"]
    direction                    = "Inbound"
    name                         = "DenyVNetInBound"
    priority                     = 123
    protocol                     = "*"
    source_address_prefix        = "*"
    source_address_prefixes      = null
    source_port_range            = "0-65535"
    source_port_ranges           = null
  }
  security_rule {
    # Any-Any Egress
    access                     = "Deny"
    destination_address_prefix = "*"
    destination_port_range     = "0-65535"
    direction                  = "Outbound"
    name                       = "DenyVNetOutBound"
    priority                   = 123
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "0-65535"
  }
}

resource "azurerm_network_security_group" "private_endpoint" {
  name                = "nsg-private_endpoint"
  location            = "eastus"
  resource_group_name = var.resource_group_name

  security_rule {
    # PE Inbound NSG Rules
    access                     = "Allow"
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "0-65535"
    direction                  = "Inbound"
    name                       = "AllowVNetInBound"
    priority                   = 120
    protocol                   = "*"
    source_address_prefix      = "10.0.0.0/8"
    source_port_range          = "0-65535"
  }
  # Any-Any Egress
  security_rule {
    access                     = "Allow"
    destination_address_prefix = "10.0.0.0/8"
    destination_port_range     = "0-65535"
    direction                  = "Outbound"
    name                       = "AllowVNetOutBound"
    priority                   = 150
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "0-65535"
  }
}

resource "azurerm_private_dns_zone" "this" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = var.resource_group_name
}

module "azure_storage_account_network_rules" {
  source               = "../../"
  tags                 = local.tags
  storage_account_name = substr(format("st%s%s%s%s", local.tags.app_code, local.tags.env, local.tags.app_instance, random_id.random_suffix.hex), 0, 24)
  resource_group_name  = var.resource_group_name

  enable_private_networking  = true
  private_endpoint_subnet_id = data.azurerm_subnet.private_endpoint.id
  dns_zone_ids               = local.private_dns_zone_map

  public_network_access_enabled = true

  network_rules = {
    # This could be a specific ip address for individual users, e.g., 20.94.5.238
    # or an ip range for a group of users (VPN), e.g., 20.128.0.0/16
    ip_rules = concat(local.tfc_ip_ranges, ["20.94.5.238"])
    #ip_rules = ["20.94.5.238"]
    virtual_network_subnet_ids = [data.azurerm_subnet.default.id, data.azurerm_subnet.private_endpoint.id]
  }

  # Turning off the CanNotDelete management lock for testing purposes
  management_locks = {
    CanNotDelete = false
  }

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