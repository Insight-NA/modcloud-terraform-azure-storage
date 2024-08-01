### Storage Account

output "storage_account_nonsensitive" {
  description = "Nonsensitive outputs of the Storage Account object."
  value = {
    storage_account_access_tier      = azurerm_storage_account.this.access_tier
    storage_account_id               = azurerm_storage_account.this.id
    storage_account_name             = azurerm_storage_account.this.name
    storage_account_kind             = azurerm_storage_account.this.account_kind
    storage_account_tier             = azurerm_storage_account.this.account_tier
    storage_account_replication_type = azurerm_storage_account.this.account_replication_type
    primary_location                 = azurerm_storage_account.this.primary_location
    secondary_location               = try(azurerm_storage_account.this.secondary_location, null)
    management_locks                 = try(azurerm_management_lock.this[*].id, null)
    storage_blob_inventory_policy    = try(azurerm_storage_blob_inventory_policy.this[*].id, null)
    primary_blob_host                = try(azurerm_storage_account.this.primary_blob_host, null)
    primary_blob_endpoint            = try(azurerm_storage_account.this.primary_blob_endpoint, null)
    secondary_blob_host              = try(azurerm_storage_account.this.secondary_blob_host, null)
    secondary_blob_endpoint          = try(azurerm_storage_account.this.secondary_blob_endpoint, null)
    primary_dfs_host                 = try(azurerm_storage_account.this.primary_dfs_host, null)
    primary_dfs_endpoint             = try(azurerm_storage_account.this.primary_dfs_endpoint, null)
    secondary_dfs_host               = try(azurerm_storage_account.this.secondary_dfs_host, null)
    secondary_dfs_endpoint           = try(azurerm_storage_account.this.secondary_dfs_endpoint, null)
    primary_file_host                = try(azurerm_storage_account.this.primary_file_host, null)
    primary_file_endpoint            = try(azurerm_storage_account.this.primary_file_endpoint, null)
    secondary_file_host              = try(azurerm_storage_account.this.secondary_file_host, null)
    secondary_file_endpoint          = try(azurerm_storage_account.this.secondary_file_endpoint, null)
    management_policy_id             = try(azurerm_storage_management_policy.this[*].id, null)
    primary_queue_endpoint           = try(azurerm_storage_account.this.primary_queue_endpoint, null)
    primary_queue_host               = try(azurerm_storage_account.this.primary_queue_host, null)
    secondary_queue_endpoint         = try(azurerm_storage_account.this.secondary_queue_endpoint, null)
    secondary_queue_host             = try(azurerm_storage_account.this.secondary_queue_host, null)
    primary_table_endpoint           = try(azurerm_storage_account.this.primary_table_endpoint, null)
    primary_table_host               = try(azurerm_storage_account.this.primary_table_host, null)
    secondary_table_endpoint         = try(azurerm_storage_account.this.secondary_table_endpoint, null)
    secondary_table_host             = try(azurerm_storage_account.this.secondary_table_host, null)
    primary_web_endpoint             = try(azurerm_storage_account.this.primary_web_endpoint, null)
    primary_web_host                 = try(azurerm_storage_account.this.primary_web_host, null)
    secondary_web_endpoint           = try(azurerm_storage_account.this.secondary_web_endpoint, null)
    secondary_web_host               = try(azurerm_storage_account.this.secondary_web_host, null)
  }
}

output "storage_account" {
  description = "The Storage Account object."
  value       = azurerm_storage_account.this
  sensitive   = true
}

output "storage_account_access_tier" {
  description = "The access tier of the Storage Account."
  value       = azurerm_storage_account.this.access_tier
}

output "storage_account_id" {
  description = "The ID of the Storage Account."
  value       = azurerm_storage_account.this.id
}

output "storage_account_kind" {
  description = "The kind of the Storage Account."
  value       = azurerm_storage_account.this.account_kind
}

output "primary_location" {
  description = "The primary location of the storage account."
  value       = azurerm_storage_account.this.primary_location
}

output "secondary_location" {
  description = "The secondary location of the storage account."
  value       = try(azurerm_storage_account.this.secondary_location, null)
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.this.name
}

output "storage_account_tier" {
  description = "The tier of the Storage Account."
  value       = azurerm_storage_account.this.account_tier
}

output "storage_account_replication_type" {
  description = "The account replication type of the Storage Account."
  value       = azurerm_storage_account.this.account_replication_type
}

output "primary_connection_string" {
  description = "The primary connection string for the storage account"
  value       = azurerm_storage_account.this.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "The secondary connection string for the storage account"
  value       = try(azurerm_storage_account.this.secondary_connection_string, null)
  sensitive   = true
}

output "primary_access_key" {
  description = "The primary access key for the storage account"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "The primary access key for the storage account."
  value       = azurerm_storage_account.this.secondary_access_key
  sensitive   = true
}

output "fqdn" {
  description = "Fqdns for storage services."
  value       = length(azurerm_storage_account.this.name) > 0 ? { for svc in local.endpoints : svc => "${azurerm_storage_account.this.name}.${svc}.core.windows.net" } : null
}

output "local_user" {
  description = "Storage Account Local User."
  value = length(azurerm_storage_account_local_user.this) > 0 ? {
    for name, user in azurerm_storage_account_local_user.this :
    name => {
      id       = user.id
      password = user.password
      sid      = user.sid
    }
  } : null
  sensitive = true
}

output "management_locks" {
  description = "Map of the management locks created"
  value = length(azurerm_management_lock.this) > 0 ? {
    for id, lock in azurerm_management_lock.this :
    id => {
      id         = lock.id
      name       = lock.name
      lock_level = lock.lock_level
      notes      = lock.notes
    }
  } : null
}

### Blob Inventory Policy

output "storage_blob_inventory_policy" {
  description = "Id of the storage blob inventory policy created."
  value       = try(azurerm_storage_blob_inventory_policy.this[*].id, null)
}

### Blob

output "storage_blob" {
  description = "Map of storage blob created."
  value = length(azurerm_storage_blob.this) > 0 ? {
    for name, blob in azurerm_storage_blob.this :
    name => {
      id                   = blob.id
      name                 = blob.name
      url                  = blob.url
      storage_account_name = blob.storage_account_name
    }
  } : null
}

output "primary_blob_connection_string" {
  description = "The connection string associated with the primary blob location."
  value       = azurerm_storage_account.this.primary_blob_connection_string
  sensitive   = true
}

output "secondary_blob_connection_string" {
  description = "The connection string associated with the secondary blob location."
  value       = azurerm_storage_account.this.secondary_blob_connection_string
  sensitive   = true
}

output "primary_blob_host" {
  description = "The hostname with port if applicable for blob storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_blob_host, null)
}

output "primary_blob_endpoint" {
  description = "The endpoint URL for blob storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_blob_endpoint, null)
}

output "primary_blob_microsoft_endpoint" {
  description = "The microsoft routing endpoint URL for blob storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_blob_microsoft_endpoint, null)
}

output "primary_blob_microsoft_host" {
  description = "The microsoft routing hostname with port if applicable for blob storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_blob_microsoft_host, null)
}

output "secondary_blob_host" {
  description = "The hostname with port if applicable for blob storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_blob_host, null)
}

output "secondary_blob_endpoint" {
  description = "The endpoint URL for blob storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_blob_endpoint, null)
}

output "secondary_blob_microsoft_host" {
  description = "The microsoft routing hostname with port if applicable for blob storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_blob_microsoft_host, null)
}

output "secondary_blob_microsoft_endpoint" {
  description = "The microsoft routing endpoint URL for blob storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_blob_microsoft_endpoint, null)
}

### Container

output "storage_container" {
  description = "Map of storage containers created."
  value = length(azurerm_storage_container.this) > 0 ? {
    for name, container in azurerm_storage_container.this :
    name => {
      id                      = container.id
      name                    = container.name
      storage_account_name    = container.storage_account_name
      container_access_type   = container.container_access_type
      has_immutability_policy = container.has_immutability_policy
      has_legal_hold          = container.has_legal_hold
      resource_manager_id     = container.resource_manager_id
    }
  } : null
}

### DFS

output "storage_data_lake_gen2_filesystem" {
  description = "Map of storage data lake gen2 filesystem created."
  value = length(azurerm_storage_data_lake_gen2_filesystem.this) > 0 ? {
    for name, filesystem in azurerm_storage_data_lake_gen2_filesystem.this :
    name => {
      id                   = filesystem.id
      name                 = filesystem.name
      properties           = filesystem.properties
      ace                  = filesystem.ace
      owner                = filesystem.owner
      group                = filesystem.group
      storage_account_name = filesystem.storage_account_id
    }
  } : null
}

output "storage_data_lake_gen2_path" {
  description = "Map of storage data lake gen2 path created."
  value = length(azurerm_storage_data_lake_gen2_path.this) > 0 ? {
    for name, path in azurerm_storage_data_lake_gen2_path.this :
    name => {
      id                   = path.id
      path                 = path.path
      ace                  = path.ace
      owner                = path.owner
      group                = path.group
      storage_account_name = path.storage_account_id
    }
  } : null
}

output "primary_dfs_host" {
  description = "The hostname with port if applicable for dfs storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_dfs_host, null)
}

output "primary_dfs_endpoint" {
  description = "The endpoint URL for dfs storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_dfs_endpoint, null)
}

output "primary_dfs_microsoft_endpoint" {
  description = "The microsoft routing endpoint URL for dfs storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_dfs_microsoft_endpoint, null)
}

output "primary_dfs_microsoft_host" {
  description = "The microsoft routing hostname with port if applicable for dfs storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_dfs_microsoft_host, null)
}

output "secondary_dfs_host" {
  description = "The hostname with port if applicable for dfs storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_dfs_host, null)
}

output "secondary_dfs_endpoint" {
  description = "The endpoint URL for dfs storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_dfs_host, null)
}

output "secondary_dfs_microsoft_host" {
  description = "The microsoft routing hostname with port if applicable for dfs storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_dfs_host, null)
}

output "secondary_dfs_microsoft_endpoint" {
  description = "The microsoft routing endpoint URL for dfs storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_dfs_microsoft_endpoint, null)
}

### Fileshare

output "storage_share" {
  description = "Map of storage shares created."
  value = length(azurerm_storage_share.this) > 0 ? {
    for name, share in azurerm_storage_share.this : name => {
      id                   = share.id
      name                 = share.name
      storage_account_name = share.storage_account_name
      access_tier          = share.access_tier
      enabled_protocol     = share.enabled_protocol
      quota                = share.quota
      resource_manager_id  = share.resource_manager_id
      url                  = share.url
    }
  } : null
}

output "storage_share_directory" {
  description = "Map of storage share directories created."
  value = length(azurerm_storage_share_directory.this) > 0 ? {
    for name, directories in azurerm_storage_share_directory.this : name => {
      id   = directories.id
      name = directories.name
    }
  } : null
}

output "storage_share_file" {
  description = "Map of storage share directories created."
  value = length(azurerm_storage_share_file.this) > 0 ? {
    for name, files in azurerm_storage_share_file.this : name => {
      id             = files.id
      name           = files.name
      content_length = files.content_length
    }
  } : null
}

output "primary_file_host" {
  description = "The hostname with port if applicable for file storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_file_host, null)
}

output "primary_file_endpoint" {
  description = "The endpoint URL for file storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_file_endpoint, null)
}

output "primary_file_microsoft_endpoint" {
  description = "The microsoft routing endpoint URL for file storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_file_microsoft_endpoint, null)
}

output "primary_file_microsoft_host" {
  description = "The microsoft routing hostname with port if applicable for file storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_file_microsoft_host, null)
}

output "secondary_file_host" {
  description = "The hostname with port if applicable for file storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_file_host, null)
}

output "secondary_file_endpoint" {
  description = "The endpoint URL for file storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_file_endpoint, null)
}

output "secondary_file_microsoft_host" {
  description = "The microsoft routing hostname with port if applicable for file storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_file_microsoft_host, null)
}

output "secondary_file_microsoft_endpoint" {
  description = "The microsoft routing endpoint URL for file storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_file_microsoft_endpoint, null)
}

### Lifecycle Management Policy

output "management_policy_id" {
  description = "ID of the management policy created"
  value       = try(azurerm_storage_management_policy.this[*].id, null)
}

### Private Endpoints

output "private_endpoint_blob" {
  description = "Blob Private Endpoint"
  value       = try(azurerm_private_endpoint.blob[0], null)
}

output "private_endpoint_table" {
  description = "Table Private Endpoint"
  value       = try(azurerm_private_endpoint.table[0], null)
}

output "private_endpoint_queue" {
  description = "Queue Private Endpoint"
  value       = try(azurerm_private_endpoint.queue[0], null)
}

output "private_endpoint_file" {
  description = "File Private Endpoint"
  value       = try(azurerm_private_endpoint.file[0], null)
}

output "private_endpoint_web" {
  description = "Blob Private Endpoint"
  value       = try(azurerm_private_endpoint.web[0], null)
}

output "private_endpoint_dfs" {
  description = "Blob Private Endpoint"
  value       = try(azurerm_private_endpoint.dfs[0], null)
}

### Queue

output "storage_queue" {
  description = "Map of storage queues created."
  value = length(azurerm_storage_queue.this) > 0 ? {
    for name, queue in azurerm_storage_queue.this :
    name => {
      id                   = queue.id
      name                 = queue.name
      storage_account_name = queue.storage_account_name
      resource_manager_id  = queue.resource_manager_id
    }
  } : null
}

output "primary_queue_endpoint" {
  description = " The endpoint URL for queue storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_queue_endpoint, null)
}

output "primary_queue_host" {
  description = "The hostname with port if applicable for queue storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_queue_host, null)
}

output "primary_queue_microsoft_endpoint" {
  description = " The microsoft endpoint URL for queue storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_queue_microsoft_endpoint, null)
}

output "primary_queue_microsoft_host" {
  description = "The microsoft hostname with port if applicable for queue storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_queue_microsoft_host, null)
}

output "secondary_queue_endpoint" {
  description = "The endpoint URL for queue storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_queue_endpoint, null)
}

output "secondary_queue_host" {
  description = "The hostname with port if applicable for queue storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_queue_host, null)
}

output "secondary_queue_microsoft_endpoint" {
  description = "The microsoft  endpoint URL for queue storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_queue_microsoft_endpoint, null)
}

output "secondary_queue_microsoft_host" {
  description = "The microsoft hostname with port if applicable for queue storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_queue_microsoft_host, null)
}

### Table

output "storage_table" {
  description = "Map of storage tables created."
  value = length(azurerm_storage_table.this) > 0 ? {
    for name, table in azurerm_storage_table.this : name => {
      id                   = table.id
      name                 = table.name
      storage_account_name = table.storage_account_name
    }
  } : null
}

output "storage_table_entity" {
  description = "Map of storage table entities created."
  value = length(azurerm_storage_table_entity.this) > 0 ? {
    for name, table_entity in azurerm_storage_table_entity.this : name => {
      id                   = table_entity.id
      partition_key        = table_entity.partition_key
      row_key              = table_entity.row_key
      storage_account_name = table_entity.storage_account_name
    }
  } : null
}

output "primary_table_endpoint" {
  description = "The endpoint with port if applicable for table storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_table_endpoint, null)
}

output "primary_table_host" {
  description = "The hostname with port if applicable for table storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_table_host, null)
}

output "primary_table_microsoft_endpoint" {
  description = "The endpoint with port if applicable for table storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_table_microsoft_endpoint, null)
}

output "primary_table_microsoft_host" {
  description = "The hostname with port if applicable for table storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_table_microsoft_host, null)
}

output "secondary_table_endpoint" {
  description = "The endpoint with port if applicable for table storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_table_endpoint, null)
}

output "secondary_table_host" {
  description = "The hostname with port if applicable for table storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_table_host, null)
}

output "secondary_table_microsoft_endpoint" {
  description = "The microsoft endpoint with port if applicable for table storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_table_microsoft_endpoint, null)
}

output "secondary_table_microsoft_host" {
  description = "The microsoft hostname with port if applicable for table storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_table_microsoft_host, null)
}

### Web

output "primary_web_endpoint" {
  description = "The endpoint with port if applicable for web storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_web_endpoint, null)
}

output "primary_web_host" {
  description = "The hostname with port if applicable for web storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_web_host, null)
}

output "primary_web_microsoft_endpoint" {
  description = "The endpoint with port if applicable for web storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_web_microsoft_endpoint, null)
}

output "primary_web_microsoft_host" {
  description = "The hostname with port if applicable for web storage in the primary location."
  value       = try(azurerm_storage_account.this.primary_web_microsoft_host, null)
}

output "secondary_web_endpoint" {
  description = "The endpoint with port if applicable for web storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_web_endpoint, null)
}

output "secondary_web_host" {
  description = "The hostname with port if applicable for web storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_web_host, null)
}

output "secondary_web_microsoft_endpoint" {
  description = "The microsoft endpoint with port if applicable for web storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_web_microsoft_endpoint, null)
}

output "secondary_web_microsoft_host" {
  description = "The microsoft hostname with port if applicable for web storage in the secondary location."
  value       = try(azurerm_storage_account.this.secondary_web_microsoft_host, null)
}