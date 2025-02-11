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
  // There is no terraform data source for backup_policy_id
  backup_policy_id             = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/rg-${var.environment_settings.environment}-${var.environment_settings.region_code}-backup/providers/Microsoft.DataProtection/backupVaults/bv-${var.environment_settings.environment}-${var.environment_settings.region_code}-backup/backupPolicies/disk-backup"
}