locals {
  mi_deployer_principal_name = "id-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-tf"
}

// These are each used in the Function Apps to connect to the Database
output "postgres_uri" {
  value = "jdbc:postgresql://${azurerm_postgresql_flexible_server.nomad.fqdn}:5432"
}

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

resource "azurerm_postgresql_flexible_server_configuration" "pgcrypto" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.nomad.id
  value     = "PGCRYPTO"
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "nomad" {
  server_name         = azurerm_postgresql_flexible_server.nomad.name
  resource_group_name = data.azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
  principal_name      = local.mi_deployer_principal_name
  principal_type      = "ServicePrincipal"
}

locals {
  postgres_dns_resolver_script_path = "${path.module}/scripts/postgres_dns_resolver.sh"
  postgres_setup_db_script_path = "${path.module}/sql/01_setup_db.sql"
}

// Ensure we have network access before trying to execute sql script
resource "terraform_data" "postgres_dns_resolver" {
  triggers_replace = [
    azurerm_postgresql_flexible_server.nomad.id
  ]

  provisioner "local-exec" {
    command = "chmod +x ${local.postgres_dns_resolver_script_path} && ./${local.postgres_dns_resolver_script_path}"

    environment = {
      POSTGRES_FQDN = azurerm_postgresql_flexible_server.nomad.fqdn
    }
  }
}

resource "terraform_data" "initialize_db" {
  provisioner "local-exec" {
    command = <<EOT
      export NOMAD_ADMIN_USER=${azurerm_user_assigned_identity.github.name}
      export NOMAD_BACKEND_USER=${azurerm_user_assigned_identity.asp.name}
      export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query "[accessToken]" -o tsv)
      psql -h ${azurerm_postgresql_flexible_server.nomad.fqdn} -p 5432 -U ${local.mi_deployer_principal_name} -d postgres -f ${local.postgres_setup_db_script_path}
      EOT
  }
  depends_on = [
    terraform_data.postgres_dns_resolver,
    azurerm_postgresql_flexible_server_active_directory_administrator.nomad
  ]
}

