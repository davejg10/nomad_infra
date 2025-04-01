data "azuread_service_principal" "hertzner" {
  display_name = "sp-${var.environment_settings.environment}-hertzner-scraper"
}

resource "azurerm_role_assignment" "hertzner_servicebus_sender" {
  scope                = azurerm_servicebus_namespace.nomad.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = data.azuread_service_principal.hertzner.object_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "hertzner_servicebus_receiver" {
  scope                = azurerm_servicebus_namespace.nomad.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = data.azuread_service_principal.hertzner.object_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "hertzner_pull_acr" {
  scope                = data.azurerm_container_registry.devopsutils.id
  role_definition_name = "AcrPull"
  principal_id         = data.azuread_service_principal.hertzner.object_id
  principal_type     = "ServicePrincipal"
}