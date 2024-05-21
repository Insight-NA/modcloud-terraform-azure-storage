output "module_outputs" {
  description = "Nonsensitive outputs of the Storage Account object."
  value       = module.azure_storage_account_premium_blockblob.storage_account_nonsensitive
}