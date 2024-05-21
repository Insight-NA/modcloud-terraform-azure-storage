output "module_outputs" {
  description = "Nonsensitive outputs of the Storage Account object."
  value       = module.azure_storage_account_network_rules.storage_account_nonsensitive
}