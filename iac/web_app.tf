resource "azurerm_service_plan" "asp" {
  name = "asp-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  os_type             = "Linux"
  sku_name            = var.asp_sku_name
}

resource "azurerm_linux_web_app" "web_app" {
  name = "web-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  service_plan_id     = azurerm_service_plan.asp.id

  key_vault_reference_identity_id = azurerm_user_assigned_identity.asp.id
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.asp.id]
  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.web_insights.instrumentation_key
    "WEBSITES_PORT"                  = var.exposed_container_port
    "WEBSITE_PULL_IMAGE_OVER_VNET"   = true
  }

  site_config {
    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = azurerm_user_assigned_identity.asp.client_id
  }

  lifecycle {
    ignore_changes = [
      tags,
      virtual_network_subnet_id,
      site_config["application_stack"] // Deploy our app separately
    ]
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_linux_web_app.web_app.id
  subnet_id      = azurerm_subnet.app_service_plan.id
}

resource "azurerm_application_insights" "web_insights" {
  name = "appi-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  application_type    = "web"
}
