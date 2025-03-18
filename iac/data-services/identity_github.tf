// Managed Identity used in nomad_data_services repo to deploy, insert secret, push to acr..
resource "azurerm_user_assigned_identity" "github" {
  name = "id-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-github"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
}

output "github_client_id" {
  value = azurerm_user_assigned_identity.github.client_id
}

resource "azurerm_role_assignment" "github_to_admin_api_fa" {
  scope              = data.azurerm_linux_function_app.admin_api.id
  role_definition_name = "Website Contributor"
  principal_id       = azurerm_user_assigned_identity.github.principal_id
}

resource "azurerm_role_assignment" "github_to_job_orchestrator_fa" {
  scope              = data.azurerm_linux_function_app.job_orchestrator.id
  role_definition_name = "Website Contributor"
  principal_id       = azurerm_user_assigned_identity.github.principal_id
}

resource "azurerm_role_assignment" "github_to_acr" {
  scope                = data.azurerm_container_registry.devopsutils.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}