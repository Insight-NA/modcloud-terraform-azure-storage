output "module_outputs" {
  description = "Nonsensitive outputs of the Storage Account object."
  value       = module.azure_storage_account_standard_storagev2.storage_account_nonsensitive
}