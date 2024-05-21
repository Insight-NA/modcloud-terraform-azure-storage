output "module_outputs" {
  description = "Nonsensitive outputs of the Storage Account object."
  value       = module.azure_storage_standard_blob.storage_account_nonsensitive
}