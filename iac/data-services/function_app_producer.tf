resource "azurerm_service_plan" "producer" {
  name                = "asp-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  os_type             = "Linux"
  sku_name            = var.sku_name
}

resource "azurerm_storage_account" "producer" {
  name                     = "st${var.environment_settings.environment}${var.environment_settings.region_code}${var.environment_settings.app_name}${var.environment_settings.identifier}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = var.environment_settings.region
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [data.terraform_remote_state.backend.outputs.data_services_subnet_id]
  }
}

resource "azurerm_linux_function_app" "producer" {
  name                = "fa-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-producer"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = var.environment_settings.region

  storage_account_name       = azurerm_storage_account.producer.name
  storage_account_access_key = azurerm_storage_account.producer.primary_access_key
  service_plan_id            = azurerm_service_plan.producer.id

  site_config {}

  lifecycle {
    ignore_changes = [
      virtual_network_subnet_id, // Managed via azurerm_app_service_virtual_network_swift_connection
    ]
  }
}

