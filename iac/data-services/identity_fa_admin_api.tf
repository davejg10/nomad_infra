resource "azurerm_user_assigned_identity" "fa_admin_api" {
  name = "id-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-admin-api"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
}

resource "azurerm_role_assignment" "admin_api_to_package_storage" {
  scope                = azurerm_storage_account.admin_api.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.fa_admin_api.principal_id
}

resource "azurerm_role_assignment" "admin_api_to_app_key_vault" {
  scope                = data.terraform_remote_state.backend.outputs.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.fa_admin_api.principal_id
}

