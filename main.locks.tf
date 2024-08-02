resource "azurerm_management_lock" "this" {
  for_each = {
    for key, lock in var.management_locks : key => lock if lock == true
  }

  name       = format("%s%s%s", "lock-", each.key, "-storage-account")
  scope      = azurerm_storage_account.this.id
  lock_level = each.key
  notes      = format("%s%s", "Storage Account level Management Lock - ", each.key)
}