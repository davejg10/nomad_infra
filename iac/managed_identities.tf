resource "azurerm_user_assigned_identity" "asp" {
  name = "id-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-asp-${var.environment_settings.identifier}"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
}

resource "azurerm_role_assignment" "web_app_fetch_secret" {
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

resource "azurerm_role_assignment" "github_to_key_vault" {
  scope                = azurerm_key_vault.nomad.id
  role_definition_id = azurerm_role_definition.manage_key_vault_secrets.role_definition_resource_id
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}
resource "azurerm_role_assignment" "github_to_acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_id = azurerm_role_definition.push_acr_image.role_definition_resource_id
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}
resource "azurerm_role_assignment" "github_to_web_app" {
  scope                = azurerm_linux_web_app.web_app.id
  role_definition_id = azurerm_role_definition.deploy_web_app_image.role_definition_resource_id
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}

resource "azurerm_role_definition" "manage_key_vault_secrets" {
  name        = "${var.environment_settings.environment}-github-helper-${var.environment_settings.app_name}"
  scope       = azurerm_key_vault.nomad.id
  description = "A custom role tallowing all secret management in Key Vault: ${azurerm_key_vault.nomad.name}."

  permissions {
    actions     = []
    data_actions = [
      "Microsoft.KeyVault/vaults/secrets/*",
    ]
    not_actions = []
  }

  assignable_scopes = [
    azurerm_key_vault.nomad.id
  ]
}

resource "azurerm_role_definition" "push_acr_image" {
  name        = "${var.environment_settings.environment}-acrpush-${azurerm_container_registry.acr.name}"
  scope       = azurerm_container_registry.acr.id
  description = "A custom role allow you to push images to the ACR: ${azurerm_container_registry.acr.name}."

  permissions {
    actions = [
        "Microsoft.ContainerRegistry/registries/pull/read",
        "Microsoft.ContainerRegistry/registries/push/write"
    ]
    data_actions = []
    not_actions = []
  }

  assignable_scopes = [
    azurerm_container_registry.acr.id
  ]
}

resource "azurerm_role_definition" "deploy_web_app_image" {
  name        = "${var.environment_settings.environment}-webapp-deploy-${azurerm_linux_web_app.web_app.name}"
  scope       = azurerm_linux_web_app.web_app.id
  description = "A custom role allow you to fetch publish_profile and deploy Web Apps to: ${azurerm_linux_web_app.web_app.name}."

  permissions {
    actions = [
      "Microsoft.Web/sites/containers/*"
    ]
    data_actions = [
      "Microsoft.Web/sites/publishingProfiles/list/action"
    ]
    not_actions = []
  }

  assignable_scopes = [
    azurerm_linux_web_app.web_app.id
  ]
}