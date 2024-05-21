#-------------------------------
# Local Declarations
#-------------------------------
locals {

  generated_storage_name = substr(format("st%s%s%s%s", local.app_code, local.app_environment, local.app_instance, random_id.random_suffix.hex), 0, 24)
  storage_name           = var.storage_account_name != null ? var.storage_account_name : local.generated_storage_name
  access_tier = (
    var.account_kind == "BlobStorage" ||
    var.account_kind == "StorageV2" ||
    var.account_kind == "FileStorage"
  ) ? var.access_tier : null

  # endpoints
  share_endpoint = length(var.storage_share) == 0 ? [] : ["file"]
  queue_endpoint = length(var.storage_queue) == 0 ? [] : ["queue"]
  table_endpoint = length(var.storage_table) == 0 ? [] : ["table"]
  dfs_endpoint   = length(var.data_lake_gen2) == 0 ? [] : ["dfs"]
  endpoints = toset(concat(
    local.share_endpoint,
    local.queue_endpoint,
    local.table_endpoint,
    local.dfs_endpoint
  ))

  # networking
  allowed_ips = distinct(concat(
    var.network_rules.hca_ips_enabled == true ? local.hca_ips : [],
  try(var.network_rules.ip_rules, []) != null ? try(var.network_rules.ip_rules, []) : [], []))
  allowed_subnets = distinct(concat(
    var.network_rules.hca_ips_enabled == true ? [
      local.tfc_agent_east_subnet_id,
      local.tfc_agent_central_subnet_id
    ] : [],
    var.network_rules.virtual_network_subnet_ids != null ? tolist(var.network_rules.virtual_network_subnet_ids) : [],
  []))
  hca_ips                     = ["internal_ip_range1", "internal_ip_range2", "internal_ip_range3"]
  tfc_agent_east_subnet_id    = "/subscriptions/<sub_id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<snet>"
  tfc_agent_central_subnet_id = "/subscriptions/<sub_id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<snet>"

  # tags
  app_code        = var.tags != null ? lower(replace(var.tags["app_code"], "/[[:^alnum:]]/", "")) : ""
  app_environment = var.tags != null ? lower(replace(var.tags["app_environment"], "/[[:^alnum:]]/", "")) : ""
  app_instance    = var.tags != null ? lower(replace(var.tags["app_instance"], "/[[:^alnum:]]/", "")) : ""

  # Blob Properties
  blob_properties_defaults = {
    versioning_enabled = true
    container_delete_retention_policy = {
      days = 7
    }
    delete_retention_policy = {
      days = 7
    }
    cors_rule                     = null
    restore_policy                = null
    last_access_time_enabled      = null
    change_feed_retention_in_days = null
    change_feed_enabled           = null
    default_service_version       = null
  }

  # Blob Creation
  blob = flatten([
    for container_key, container in var.storage_container : [
      for blob_key, blob in container.blob != null ? container.blob : [] : {
        container_key  = container_key
        blob_key       = blob_key
        container_name = container.name
        name           = blob.name
        type           = blob.type
        size           = blob.size
        access_tier    = blob.access_tier
        cache_control  = blob.cache_control
        content_type   = blob.content_type
        content_md5    = blob.content_md5
        source         = blob.source
        source_content = blob.source_content
        source_uri     = blob.source_uri
        parallelism    = blob.parallelism
        metadata       = blob.metadata
        timeouts       = blob.timeouts
      }
    ]
  ])

  # Share Properties
  share_properties_defaults = {
    retention_policy = {
      days = 7
    }
    cors_rule = null
    smb       = null
  }

  share_properties = (
    var.account_kind == "BlockBlobStorage" ? null :
    var.share_properties != null ? var.share_properties : local.share_properties_defaults
  )

  # Share Directory Creation
  directories = flatten([
    for share_key, share in var.storage_share : [
      for directories_key, directories in share.directories != null ? share.directories : [] : {
        share_key        = share_key
        directories_key  = directories_key
        share_name       = share.name
        directories_name = directories.name
        metadata         = directories.metadata
        timeouts         = directories.timeouts
      }
    ]
  ])

  # Share File Creation
  files = flatten([
    for share_key, share in var.storage_share : [
      for directories_key, directories in share.directories != null ? share.directories : [] : [
        for files_key, files in directories.files != null ? directories.files : [] : {
          share_key           = share_key
          directories_key     = directories_key
          files_key           = files_key
          name                = files.name
          storage_share_id    = azurerm_storage_share.this[share.name].id
          path                = directories.name
          source              = files.source
          content_type        = files.content_type
          content_md5         = files.content_md5
          content_encoding    = files.content_encoding
          content_disposition = files.content_disposition
          metadata            = files.metadata
          timeouts            = files.timeouts
        }
      ]
    ]
  ])

  # Table Entity Creation
  entities = flatten([
    for table_key, table in var.storage_table : [
      for entity_key, entity in table.entities != null ? table.entities : {} : {
        table_key     = table_key
        entity_key    = entity_key
        table_name    = table.name
        partition_key = entity.partition_key
        row_key       = entity.row_key
        entity        = entity.entity
      }
    ]
  ])

  # Data Lake Gen2 Path Creation
  directory = flatten([
    for filesystem_key, filesystem in var.data_lake_gen2 : [
      for directory_key, directory in filesystem.directory != null ? filesystem.directory : [] : {
        filesystem_key  = filesystem_key
        directory_key   = directory_key
        filesystem_name = filesystem.name
        path            = directory.path
        owner           = directory.owner
        group           = directory.group
        ace             = directory.ace
      }
    ]
  ])
}

