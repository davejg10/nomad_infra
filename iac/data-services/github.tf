resource "azurerm_federated_identity_credential" "github" {
  name = "${var.github_repository_name}-${var.environment_settings.environment}"

  resource_group_name = data.azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  parent_id           = azurerm_user_assigned_identity.github.id
  subject             = "repo:${var.github_organisation_target}/${var.github_repository_name}:environment:${var.environment_settings.environment}"
}

// Managed Identity used in nomad-producer repo to deploy, insert secret, push to acr..
resource "azurerm_user_assigned_identity" "github" {
  name = "id-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-github-${var.environment_settings.identifier}"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
}

output "github_client_id" {
  value = azurerm_user_assigned_identity.github.client_id
}

resource "azurerm_role_assignment" "github_to_function_apps" {
  scope              = data.azurerm_resource_group.rg.id
  role_definition_id = azurerm_role_definition.deploy_function_app_image.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.github.principal_id
}

resource "azurerm_role_definition" "deploy_function_app_image" {
  name        = "nomad-deploy-function-app-dev"
  scope       = data.azurerm_resource_group.rg.id
  description = "A custom role allow you to fetch publish_profile and deploy Functions Apps in : ${data.azurerm_resource_group.rg.name}."

  permissions {
    actions = [
      "Microsoft.Web/sites/read",
      "Microsoft.Web/sites/publishxml/action",
      "Microsoft.Web/serverfarms/read"
    ]
    data_actions = []
    not_actions  = []
  }

  assignable_scopes = [
    data.azurerm_resource_group.rg.id
  ]
}

// This role definition is created in 'devops' repo under 'management' config
resource "azurerm_role_assignment" "github_to_acr" {
  scope                = data.azurerm_container_registry.devopsutils.id
  role_definition_name = "acr-task-run"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}