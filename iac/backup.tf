
data "azurerm_data_protection_backup_vault" "vault" {
  name                = "bv-${var.environment_settings.environment}-${var.environment_settings.region_code}-backup"
  resource_group_name = "rg-${var.environment_settings.environment}-${var.environment_settings.region_code}-backup"
}

resource "azurerm_data_protection_backup_instance_disk" "neo4j" {
  name                         = "${azurerm_linux_virtual_machine.neo4j.name}-datadisk-backup"
  location                     = data.azurerm_data_protection_backup_vault.vault.location
  vault_id                     = data.azurerm_data_protection_backup_vault.vault.id
  disk_id                      = azurerm_managed_disk.neo4j.id
  snapshot_resource_group_name = "rg-${var.environment_settings.environment}-${var.environment_settings.region_code}-backup-snapshots"
  // There is no terraform data source for backup_policy_id
  backup_policy_id             = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${data.azurerm_data_protection_backup_vault.vault.resource_group_name}/providers/Microsoft.DataProtection/backupVaults/${data.azurerm_data_protection_backup_vault.vault.name}/backupPolicies/disk-backup"

  lifecycle {
    ignore_changes = [ // If we ever restore, and import then disk_id may be different, which will mean this instance gets replaced
      disk_id // and we lose all our snapshots..
    ]
  }
}