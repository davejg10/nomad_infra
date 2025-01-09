resource "azurerm_user_assigned_identity" "asp" {
  name = "id-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-asp-${var.environment_settings.identifier}"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
}

resource "azurerm_role_assignment" "webapp_fetch_secret" {
  scope                = azurerm_key_vault.nomad.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.asp.principal_id
}

resource "azurerm_role_assignment" "webapp_pull_acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.asp.principal_id
}

// Identity used in nomad-backend repo to deploy, insert secret, push to acr..
resource "azurerm_user_assigned_identity" "github" {
  name = "id-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-github-${var.environment_settings.identifier}"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
}

resource "azurerm_role_assignment" "github_to_key_Vault" {
  scope                = "/subscriptions/fd1f9c42-234f-4f5a-b49c-04bcfb79351d"
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}
# resource "azurerm_role_assignment" "github_to_key_Vault" {
#   scope                = azurerm_key_vault.nomad.id
#   role_definition_name = "Key Vault Secrets Officer"
#   principal_id         = azurerm_user_assigned_identity.github.principal_id
# }
# resource "azurerm_role_assignment" "github_to_key_Vault" {
#   scope                = azurerm_key_vault.nomad.id
#   role_definition_name = "Key Vault Secrets Officer"
#   principal_id         = azurerm_user_assigned_identity.github.principal_id
# }