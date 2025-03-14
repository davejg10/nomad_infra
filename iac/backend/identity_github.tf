// Managed Identity used in nomad-backend repo to deploy, insert secret, push to acr..
resource "azurerm_user_assigned_identity" "github" {
  name = "id-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-github"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
}

output "github_client_id" {
  value = azurerm_user_assigned_identity.github.client_id
}

resource "azurerm_role_assignment" "github_to_key_vault" {
  scope              = azurerm_key_vault.nomad.id
  role_definition_id = azurerm_role_definition.manage_key_vault_secrets.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.github.principal_id
}

// This role definition is created in 'devops' repo under 'management' config
resource "azurerm_role_assignment" "github_to_acr" {
  scope                = data.azurerm_container_registry.devopsutils.id
  role_definition_name = "acr-task-run"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}

resource "azurerm_role_assignment" "github_to_web_app" {
  scope              = azurerm_linux_web_app.web_app.id
  role_definition_id = azurerm_role_definition.deploy_web_app_image.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.github.principal_id
}

resource "azurerm_role_definition" "manage_key_vault_secrets" {
  name        = "kv-secrets-${azurerm_key_vault.nomad.name}"
  scope       = azurerm_key_vault.nomad.id
  description = "A custom role allowing all secret management in Key Vault: ${azurerm_key_vault.nomad.name}."

  permissions {
    actions = []
    data_actions = [
      "Microsoft.KeyVault/vaults/secrets/*",
    ]
    not_actions = []
  }

  assignable_scopes = [
    azurerm_key_vault.nomad.id
  ]
}

resource "azurerm_role_definition" "deploy_web_app_image" {
  name        = "webapp-deploy-${azurerm_linux_web_app.web_app.name}"
  scope       = azurerm_linux_web_app.web_app.id
  description = "A custom role allow you to fetch publish_profile and deploy Web Apps to: ${azurerm_linux_web_app.web_app.name}."

  permissions {
    actions = [
      "Microsoft.Web/sites/publishxml/action"
    ]
    data_actions = []
    not_actions  = []
  }

  assignable_scopes = [
    azurerm_linux_web_app.web_app.id
  ]
}