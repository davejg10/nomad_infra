resource "random_password" "postgres_pwd" {
  length           = 12
  special          = true
  override_special = "_=+:?[]"
}

resource "azurerm_key_vault_secret" "postgres_pwd" {
  name         = var.postgres_password_secret_key
  value        = random_password.postgres_pwd.result
  key_vault_id = azurerm_key_vault.nomad.id
}

// These are each used in the Function Apps to connect to the Database
output "postgres_user" {
  value = var.postgres_user
}
output "postgres_uri" {
  value = "jdbc:postgresql://${azurerm_postgresql_flexible_server.nomad.fqdn}:5432/${var.postgres_database_name}"
}
output "postgres_password_secret_key" {
  value = var.postgres_password_secret_key
}

# https://medium.com/@fedosov.evg_70413/managing-azure-postgresql-flexible-servers-with-terraform-5bd549a0ef34

resource "azurerm_postgresql_flexible_server" "nomad" {
  name                          = "psql-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = var.environment_settings.region
  version                       = "16"
  delegated_subnet_id           = azurerm_subnet.postgresql.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgresql.id
  public_network_access_enabled = false
  administrator_login           = var.postgres_user
  administrator_password        = random_password.postgres_pwd.result
  zone                          = "1"

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

resource "terraform_data" "setup_db" {
  provisioner "local-exec" {
    command = <<EOT
      sudo apt install postgresql
      export PGPASSWORD=${random_password.postgres_pwd.result}
      psql -h ${azurerm_postgresql_flexible_server.nomad.fqdn} -p 5432 -U ${var.psql_user} -d postgres -f ${local.postgres_setup_db_script_path}
      EOT
  }
  depends_on = [terraform_data.postgres_dns_resolver]
}