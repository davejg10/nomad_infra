resource "azurerm_servicebus_namespace" "nomad" {
  name                = "sbns-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  sku                 = "Standard"

  local_auth_enabled            = false
  // Service bus is public as Service Endpoints/Private Endpoints is a premium feature
  // Premium costs 70p per hour!
  public_network_access_enabled = true
}

resource "azurerm_role_assignment" "servicebus_sender" {
  scope                = azurerm_servicebus_namespace.nomad.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = data.azurerm_linux_function_app.producer.identity[0].principal_id
}

resource "azurerm_servicebus_queue" "one2goasia" {
  name         = "nomad_12goasia"
  namespace_id = azurerm_servicebus_namespace.nomad.id
}