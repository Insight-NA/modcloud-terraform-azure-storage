# Changelog
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.2.1](https://github.com/hca-ccoe/terraform-azure-storageaccount/releases/tag/v4.2.1) 2024-04-29

### Features

- Limited 'LRS' replication type to non-production storage accounts
- Implemented 7 or greater day delete retention policy for containers and blobs
- Updated share properties with a 7 or greater day retention policy, and simplified SMB version setting.
- Removed unnecessary example links from README

## [4.2.0](https://github.com/hca-ccoe/terraform-azure-storageaccount/releases/tag/v4.2.0) 2024-03-16

### Features

- Outputs
  - Added sensitive outputs, like connection strings, allowing users to programmatically reference. 
  - Added primary and secondary host, endpoint, microsoft host, and microsoft endpoint outputs for
    blob, dfs, file, queue, table, and web services.
  - Added storage_account_nonsensitive output, which contains over three dozen nonsensitive outputs,
    for easier user usage.

- Providers
  - Incremented hcaazurem3 and random to latest available versions

## [4.1.0](https://github.com/hca-ccoe/terraform-azure-storageaccount/releases/tag/v4.1.0) 2024-02-28

### Features

- Management Locks
  - CanNotDelete: Authorized users are able to read and modify the resources, but not delete. Defaults to `true`. The CanNotDelete setting will NOT prevent Terraform from destorying the storage account.
  - ReadOnly: Authorized users can only read from a resource, but they can't modify or delete. Defaults to `false`. Once a ReadOnly lock is deployed, no further modifications can take place, including Terraform changes. This lock will have to be removed manually, through the command line, or via the Azure Portal. Navigate to the storage account, and under the left navigation panel, the Settings grouping, select Locks, then delete the lock. Be sure to remove the ReadOnly setting, or set it to `false`, to prevent it from recreating.

## [4.0.0](https://github.com/hca-ccoe/terraform-azure-storageaccount/releases/tag/v4.0.0) 2024-02

### Features

- Azure Storage Account
  - Azure Files Authentication
  - Blob Properties
  - Custom Domain
  - Identity
  - Immutability Policy
  - Queue Properties
  - Routing
  - SAS Policy
  - Share Properties
  - Static Website
- Lifecycle Management Policy
- Blob Inventory Policy
- File Share
  - Access Tier
  - Enabled Protocol
  - Access Control List
  - Access Policy
- File Share Directories
- File Share Files
- Queue
- Table
  - Access Control List
  - Access Policy
- Table Entities
- Data Lake Gen2 Filesystem
- Data Lake Gen2 Path