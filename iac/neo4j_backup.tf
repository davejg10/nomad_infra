locals {
  deploy_from_backup = var.neo4j_backup_disk_name == "null" ? false : true
  neo4j_managed_disk_id = local.deploy_from_backup ? data.azurerm_managed_disk.neo4j_backup[0].id : azurerm_managed_disk.neo4j[0].id
}

resource "azurerm_managed_disk" "neo4j" {
  count = local.deploy_from_backup ? 0 : 1

  name                 = "${local.neo4j_vm_name}-neo4j-datadisk"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.neo4j_data_disk_size_gb
}

# This ISNT a disk created from azurerm_data_protection_backup_instance_disk.neo4j. 
# This is a disk created from the disk created when a VM is destroyed. See lifecycle method in neo4j.tf
data "azurerm_managed_disk" "neo4j_backup" {
  count = local.deploy_from_backup ? 1 : 0

  name                 = var.neo4j_backup_disk_name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

resource "azurerm_virtual_machine_data_disk_attachment" "neo4j" {
  managed_disk_id    = local.neo4j_managed_disk_id
  virtual_machine_id = azurerm_linux_virtual_machine.neo4j.id
  lun                = "10"
  caching            = "ReadWrite"

  provisioner "local-exec" {
    when = destroy
    command = "az disk create --resource-group $RESOURCE_GROUP_NAME --name $DISK_NAME --sku StandardSSD_LRS --size-gb $SIZE_GB --source $SNAPSHOT_ID"

    environment = {
      SNAPSHOT_ID         = self.managed_disk_id
      DISK_NAME           = "${var.neo4j_backup_disk_prefix}-${timestamp()}"
      RESOURCE_GROUP_NAME = "rg-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"
      SIZE_GB             = var.neo4j_data_disk_size_gb
    }
  }
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
  snapshot_resource_group_name = local.snapshot_resource_group_name
  backup_policy_id             = "/subscriptions/73a3c766-6179-4571-acb5-72b4c3b810bb/resourceGroups/rg-dev-uks-backup/providers/Microsoft.DataProtection/backupVaults/bv-dev-uks-backup/backupPolicies/disk-backup"

  
}