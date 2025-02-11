
data "azurerm_data_protection_backup_vault" "vault" {
  name                = "bv-${var.environment_settings.environment}-${var.environment_settings.region_code}-backup"
  resource_group_name = "rg-${var.environment_settings.environment}-${var.environment_settings.region_code}-backup"
}

resource "azurerm_data_protection_backup_instance_disk" "neo4j" {
  name                         = "neo4j-datadisk-backup"
  location                     = data.azurerm_data_protection_backup_vault.vault.location
  vault_id                     = data.azurerm_data_protection_backup_vault.vault.id
  disk_id                      = local.neo4j_managed_disk_id
  snapshot_resource_group_name = local.snapshot_resource_group_name
  backup_policy_id             = "/subscriptions/73a3c766-6179-4571-acb5-72b4c3b810bb/resourceGroups/rg-dev-uks-backup/providers/Microsoft.DataProtection/backupVaults/bv-dev-uks-backup/backupPolicies/disk-backup"
}