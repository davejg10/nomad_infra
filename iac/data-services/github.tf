resource "azurerm_federated_identity_credential" "github" {
  name = "${var.github_repository_name}-${var.environment_settings.environment}"

  resource_group_name = data.azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  parent_id           = azurerm_user_assigned_identity.github.id
  subject             = "repo:${var.github_organisation_target}/${var.github_repository_name}:environment:${var.environment_settings.environment}"
}

