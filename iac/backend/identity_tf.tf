// Managed Identity deploying this Terraform
resource "azurerm_role_assignment" "this_deployer_key_vault_secrets" {
  scope              = azurerm_key_vault.nomad.id
  role_definition_id = azurerm_role_definition.manage_key_vault_secrets.role_definition_resource_id
  principal_id       = data.azurerm_client_config.current.object_id
}