resource "azurerm_servicebus_namespace" "example" {
  name                = "tfex-servicebus-namespace"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = var.environment_settings.region
  sku                 = "Standard"

  local_auth_enabled            = false
  public_network_access_enabled = false

  network_rule_set {
    default_action = "Deny"
    public_network_access_enabled = false
    ip_rules = ["82.133.78.250"]
    network_rules {
      subnet_id = data.terraform_remote_state.backend.outputs.data_services_subnet_id
    }
  }
}

resource "azurerm_servicebus_queue" "example" {
  name         = "tfex_servicebus_queue"
  namespace_id = azurerm_servicebus_namespace.example.id

  partitioning_enabled = true
}