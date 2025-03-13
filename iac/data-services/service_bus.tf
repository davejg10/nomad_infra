resource "azurerm_servicebus_namespace" "nomad" {
  name                = "sbns-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  sku                 = "Standard"

  local_auth_enabled = var.service_bus_local_auth
  // Service bus is public as Service Endpoints/Private Endpoints is a premium feature
  // Premium costs 70p per hour!
  public_network_access_enabled = true
}

resource "azurerm_servicebus_queue" "pre_processed" {
  name         = "nomad_pre_processed"
  namespace_id = azurerm_servicebus_namespace.nomad.id
}

resource "azurerm_servicebus_queue" "processed" {
  name         = "nomad_processed"
  namespace_id = azurerm_servicebus_namespace.nomad.id
}