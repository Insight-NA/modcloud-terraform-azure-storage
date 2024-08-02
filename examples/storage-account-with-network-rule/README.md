- [How to Use this Module](#how-to-use-this-module)
- [Azure Storage Network Security](#azure-storage-network-security)
- [Azure Storage Redundency](#azure-storage-redundency)

## How to Use this Module

This example will create a Standard StorageV2 with Read-Access Geo-Redunant replication storage account with customized network rules. 

ip_rules accepts a list of public IPv4 address and IPv4 ranges in CIDR format, e.g., ["199.91.0.42", "199.91.48.0/23"]. Not allowed are /31 & /32 CIDRs, and the RFC 1918 Private IP address ranges.

virtual_network_subnet_ids accepts a list of resource ids for subnets. Ideally, this would done using a terraform data or module reference, but it can also be specified manually using this format:
```
/subscriptions/{subscriptionID}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/subnets/{subnetID}
```

WARNING: If leveraging Terraform Cloud, you may need to have internally controlled runners with terraform cloud agents installed, and linking the subnet id's of where those runner machines reside, e.g., /subscriptions/<sub_id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<snet> to the network_rules virtual_network_subnet_ids. Failure to do so may result in resources being deployed, but subsequent attempts to modify resources may produce a 403 Authorization Failure error.

```hcl
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
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.resource_group_name
}

resource "azurerm_subnet" "private_endpoint" {
  name                 = "private_endpoint"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.5.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "random_id" "random_suffix" {
  byte_length = 8
}

resource "azurerm_private_dns_zone" "this" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = var.resource_group_name
}

module "azure_storage_account_network_rules" {
  source  = "app.terraform.io/insight/azure-storage/terraform"
  version = "1.0.0"

  tags                 = local.tags
  storage_account_name = substr(format("st%s%s%s%s", local.tags.app_code, local.tags.env, local.tags.app_instance, random_id.random_suffix.hex), 0, 24)
  resource_group_name  = var.resource_group_name

  enable_private_networking  = true
  private_endpoint_subnet_id = azurerm_subnet.private_endpoint.id
  dns_zone_ids               = local.private_dns_zone_map

  network_rules = {
    # This could be a specific ip address for individual users, e.g., 20.94.5.238
    # or an ip range for a group of users (VPN), e.g., 20.128.0.0/16
    ip_rules                   = ["20.94.5.238"]
    virtual_network_subnet_ids = [data.azurerm_subnet.default.id, azurerm_subnet.private_endpoint.id]
  }

  # Turning off the CanNotDelete management lock for testing purposes
  management_locks = {
    CanNotDelete = false
  }
}
```

## Azure Storage Network Security
Azure Storage provides a layered security model. This model enables you to control the level of access to your storage accounts that your applications and enterprise environments demand, based on the type and subset of networks or resources that you use.

When you configure network rules, only applications that request data over the specified set of networks or through the specified set of Azure resources can access a storage account. You can limit access to your storage account to requests that come from specified IP addresses, IP ranges, subnets in an Azure virtual network, or resource instances of some Azure services. For more information refer to the [azure documentation](https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security?tabs=azure-portal)

## Azure Storage Redundency

To check the requirements for storage account skus or types of redundency please refer to the [azure documentation](https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy?toc=%2Fazure%2Fstorage%2Fblobs%2Ftoc.json&bc=%2Fazure%2Fstorage%2Fblobs%2Fbreadcrumb%2Ftoc.json#summary-of-redundancy-options).  

Some skus or redundency types are not available in all regions. 
