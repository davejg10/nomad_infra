locals {
  neo4j_snapshot_found = var.neo4j_disk_snapshot_name == "null" ? false : true  
  neo4j_managed_disk_id = var.neo4j_snapshot_found ? azurerm_managed_disk.neo4j_snapshot_copy[0].id : azurerm_managed_disk.neo4j[0].id
}


resource "azurerm_managed_disk" "neo4j" {
  count = local.neo4j_snapshot_found ? 0 : 1

  name                 = "${local.neo4j_vm_name}-neo4j-datadisk"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.neo4j_data_disk_size_gb
}

data "azurerm_snapshot" "neo4j" {
  count = local.neo4j_snapshot_found ? 1 : 0
  
  name                = var.neo4j_disk_snapshot_name
  resource_group_name = var.backup_vault_rg_name
}

resource "azurerm_managed_disk" "neo4j_snapshot_copy" {
  count = local.neo4j_snapshot_found ? 1 : 0

  name                 = "${local.neo4j_vm_name}-${var.neo4j_disk_snapshot_name}"
  resource_group_name  = data.azurerm_resource_group.rg.name
  location             = var.environment_settings.region
  storage_account_type = "Standard_LRS"
  create_option        = "Copy"
  source_resource_id   = data.azurerm_snapshot.neo4j[0].id
  disk_size_gb         = var.neo4j_data_disk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "neo4j" {
  managed_disk_id    = local.neo4j_managed_disk_id
  virtual_machine_id = azurerm_linux_virtual_machine.neo4j.id
  lun                = "10"
  caching            = "ReadWrite"
}

data "azurerm_data_protection_backup_vault" "vault" {
  name                = "bv-${var.environment_settings.environment}-${var.environment_settings.region_code}-backup"
  resource_group_name = "rg-${var.environment_settings.environment}-${var.environment_settings.region_code}-backup"
}

resource "azurerm_data_protection_backup_instance_disk" "neo4j" {
  name                         = "neo4j-datadisk-backup"
  location                     = data.azurerm_data_protection_backup_vault.vault.location
  vault_id                     = data.azurerm_data_protection_backup_vault.vault.id
  disk_id                      = local.neo4j_managed_disk_id
  snapshot_resource_group_name = "rg-${var.environment_settings.environment}-${var.environment_settings.region_code}-backup-snapshots"
  backup_policy_id             = "/subscriptions/73a3c766-6179-4571-acb5-72b4c3b810bb/resourceGroups/rg-dev-uks-backup/providers/Microsoft.DataProtection/backupVaults/bv-dev-uks-backup/backupPolicies/disk-backup"
}