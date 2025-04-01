data "azuread_service_principal" "hetzner" {
  display_name = "sp-${var.environment_settings.environment}-hetzner-scraper"
}

resource "azurerm_role_assignment" "hetzner_servicebus_sender" {
  scope                = azurerm_servicebus_namespace.nomad.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = data.azuread_service_principal.hetzner.object_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "hetzner_servicebus_receiver" {
  scope                = azurerm_servicebus_namespace.nomad.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = data.azuread_service_principal.hetzner.object_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "hetzner_pull_acr" {
  scope                = data.azurerm_container_registry.devopsutils.id
  role_definition_name = "AcrPull"
  principal_id         = data.azuread_service_principal.hetzner.object_id
  principal_type     = "ServicePrincipal"
}