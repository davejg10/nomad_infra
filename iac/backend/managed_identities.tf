// Managed Identity deploying this Terraform
resource "azurerm_role_assignment" "this_deployer_key_vault_secrets" {
  scope              = azurerm_key_vault.nomad.id
  role_definition_id = azurerm_role_definition.manage_key_vault_secrets.role_definition_resource_id
  principal_id       = data.azurerm_client_config.current.object_id
}

// Managed Identity used in Web App hosting application
resource "azurerm_user_assigned_identity" "asp" {
  name = "id-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-asp"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
}

resource "azurerm_role_assignment" "web_app_fetch_secret" {
  scope                = azurerm_key_vault.nomad.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.asp.principal_id
}

resource "azurerm_role_assignment" "webapp_pull_acr" {
  scope                = data.azurerm_container_registry.devopsutils.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.asp.principal_id
}

// Managed identity for PostgreSQL Database Admin - will be made OWNER of `nomad` database
resource "azurerm_user_assigned_identity" "psql_admin" {
  name = "id-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-psql"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
}