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
}

resource "azurerm_private_endpoint" "key_vault" {
  name = "pe-kv-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "pe-kv-serviceconnection-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"
    private_connection_resource_id = azurerm_key_vault.nomad.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.vault.id]
  }
}

data "azurerm_private_dns_zone" "vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.hub_rg_name
}

output "key_vault_id" {
  value = azurerm_key_vault.nomad.id
}