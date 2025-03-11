// Managed Identity used in nomad_data_services repo to deploy, insert secret, push to acr..
resource "azurerm_user_assigned_identity" "github" {
  name = "id-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-github"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
}

output "github_client_id" {
  value = azurerm_user_assigned_identity.github.client_id
}

locals {
  function_app_ids = [
    data.azurerm_linux_function_app.admin_api.id,
    data.azurerm_linux_function_app.job_orchestrator.id
  ]
}

resource "azurerm_role_assignment" "github_to_function_apps" {
  for_each = {
    for id in local.function_app_ids : id => id
  }
  
  scope              = each.key
  role_definition_name = "Website Contributor"
  principal_id       = azurerm_user_assigned_identity.github.principal_id
}


// This role definition is created in 'devops' repo under 'management' config
resource "azurerm_role_assignment" "github_to_acr" {
  scope                = data.azurerm_container_registry.devopsutils.id
  role_definition_name = "acr-task-run"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}