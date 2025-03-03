resource "azurerm_user_assigned_identity" "function_app" {
  name = "id-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-function-app"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
}

resource "azurerm_role_assignment" "job_orchestratorr_to_package_storage" {
  scope                = azurerm_storage_account.job_orchestrator.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.function_app.principal_id
}

resource "azurerm_role_assignment" "job_orchestrator_to_app_key_vault" {
  scope                = data.terraform_remote_state.backend.outputs.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.function_app.principal_id
}

resource "azurerm_storage_container" "job_orchestrator_container" {
  name                  = var.job_orchestrator_blob_container_name
  storage_account_id    = azurerm_storage_account.job_orchestrator.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "job_orchestrator_servicebus_sender" {
  scope                = azurerm_servicebus_namespace.nomad.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_user_assigned_identity.function_app.principal_id
}
resource "azurerm_role_assignment" "job_orchestrator_servicebus_receiver" {
  scope                = azurerm_servicebus_namespace.nomad.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_user_assigned_identity.function_app.principal_id
}