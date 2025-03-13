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