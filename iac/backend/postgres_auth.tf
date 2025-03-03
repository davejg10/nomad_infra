locals {
  mi_deployer_principal_name = "id-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-tf"
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
  postgres_setup_db_script_path = "${path.module}/scripts/initialize_db.sql"
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
  triggers_replace = timestamp()

  provisioner "local-exec" {
    command = <<EOT
      export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query "[accessToken]" -o tsv)
      psql -h "${azurerm_postgresql_flexible_server.nomad.fqdn}" -p 5432 -U "${local.mi_deployer_principal_name}" -d postgres -f ${local.postgres_setup_db_script_path} -v NEO4J_USER="${azurerm_user_assigned_identity.neo4j.name}" -v NOMAD_BACKEND_USER="${azurerm_user_assigned_identity.asp.name}"
      EOT
  }

  depends_on = [
    terraform_data.postgres_dns_resolver,
    azurerm_postgresql_flexible_server_active_directory_administrator.nomad
  ]
}

