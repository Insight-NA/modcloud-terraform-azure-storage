output "module_outputs" {
  description = "Nonsensitive outputs of the Storage Account object."
  value       = module.azure_storage_queue.storage_account_nonsensitive
}