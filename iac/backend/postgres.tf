resource "azurerm_postgresql_flexible_server" "nomad" {
  name                          = "psql-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = var.environment_settings.region
  version                       = "16"
  delegated_subnet_id           = azurerm_subnet.postgresql.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgresql.id
  public_network_access_enabled = false
  zone                          = "1"

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = false
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  backup_retention_days = var.postgres_backup_retention_days

  storage_mb   = var.postgres_storage_mb
  storage_tier = var.postgres_storage_tier

  sku_name   = var.postges_sku_name

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres_this_vnet,
    azurerm_private_dns_zone_virtual_network_link.postgres_hub_vnet
  ]

}

// These are each used in the Function Apps to connect to the Database
output "postgres_uri" {
  value = "jdbc:postgresql://${azurerm_postgresql_flexible_server.nomad.fqdn}:5432/nomad?sslmode=require"
}
output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.nomad.fqdn
}

resource "azurerm_postgresql_flexible_server_configuration" "pgcrypto" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.nomad.id
  value     = "PGCRYPTO"
}
