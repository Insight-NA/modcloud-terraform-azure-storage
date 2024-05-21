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

WARNING: The hca_ips_enabled boolean attribute is 'true' by default, and should only be modified in extremely specific use cases. The hca_ips_enabled boolean attribute adds a network rule enabling the HCA Terraform Cloud Agent East 2 US and Central US networks access to resources deployed by terraform; additionally IP address ranges for VPN users is added. Setting this attribute to false may prevent terraform from fully deploying all requested resources and it WILL BE UNABLE to modify any resources once deployed (403 Authorization Failure error).

```hcl
data "azurerm_subnet" "test_sub" {
  provider             = hcaazurerm3
  name                 = "default"
  virtual_network_name = "module-testing-vnet"
  resource_group_name  = var.resource_group_name
}

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

module "azure_storage_account_network_rules" {
  source                     = "app.terraform.io/hca-healthcare/storageaccount/azure"
  version                    = "~>4.2.0"
  tags                = module.tagging.labels
  resource_group_name = var.resource_group_name
  network_rules = {
    ip_rules = ["127.0.0.1", "127.0.113.0/24"]
    virtual_network_subnet_ids = [data.azurerm_subnet.test_sub.id]
  }
}
```

## Azure Storage Network Security
Azure Storage provides a layered security model. This model enables you to control the level of access to your storage accounts that your applications and enterprise environments demand, based on the type and subset of networks or resources that you use.

When you configure network rules, only applications that request data over the specified set of networks or through the specified set of Azure resources can access a storage account. You can limit access to your storage account to requests that come from specified IP addresses, IP ranges, subnets in an Azure virtual network, or resource instances of some Azure services. For more information refer to the [azure documentation](https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security?tabs=azure-portal)

## Azure Storage Redundency

To check the requirements for storage account skus or types of redundency please refer to the [azure documentation](https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy?toc=%2Fazure%2Fstorage%2Fblobs%2Ftoc.json&bc=%2Fazure%2Fstorage%2Fblobs%2Fbreadcrumb%2Ftoc.json#summary-of-redundancy-options).  

Some skus or redundency types are not available in all regions. 
