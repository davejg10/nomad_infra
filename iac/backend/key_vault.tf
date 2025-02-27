data "azurerm_subnet" "ghrunners" {
  name                 = var.ghrunner_subnet_name
  virtual_network_name = var.hub_vnet_name
  resource_group_name  = var.hub_rg_name
}

resource "azurerm_key_vault" "nomad" {
  name = "kv-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  tenant_id           = data.azurerm_client_config.current.tenant_id

  soft_delete_retention_days = var.kv_soft_delete_retention_days
  purge_protection_enabled   = var.kv_purge_protection_enabled
  enable_rbac_authorization  = true

  sku_name = var.key_vault_sku_name

  public_network_access_enabled = var.kv_public_network_access_enabled

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    virtual_network_subnet_ids = [
      azurerm_subnet.data_services.id,
      azurerm_subnet.neo4j.id,
      azurerm_subnet.app_service_plan.id,
      data.azurerm_subnet.ghrunners.id
    ]
  }
}

output "key_vault_id" {
  value = azurerm_key_vault.nomad.id
}
output "key_vault_uri" {
  value = azurerm_key_vault.nomad.vault_uri
}
