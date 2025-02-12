resource "azurerm_service_plan" "asp" {
  name = "asp-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  os_type             = "Linux"
  sku_name            = var.asp_sku_name
}

resource "azurerm_linux_web_app" "web_app" {
  name = "web-t-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  service_plan_id     = azurerm_service_plan.asp.id

  key_vault_reference_identity_id = azurerm_user_assigned_identity.asp.id
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.asp.id]
  }

  app_settings = {
    "WEBSITES_PORT"                         = var.exposed_container_port
    "NEO4J_URI"                             = "bolt://${var.neo4j_static_private_ip}:7687"
    "NEO4J_USER"                            = var.neo4j_user
    "NEO4J_PASSWORD"                        = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.neo4j_pwd.id})"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.web_insights.connection_string
  }

  site_config {
    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = azurerm_user_assigned_identity.asp.client_id
    vnet_route_all_enabled                        = true
  }

  logs {
    application_logs {
      file_system_level = "Information"
    }
    http_logs { 
      file_system {
        retention_in_days = 7
        retention_in_mb = 35
      }
    }
  }

  lifecycle {
    ignore_changes = [
      virtual_network_subnet_id, // Managed via azurerm_app_service_virtual_network_swift_connection below
      site_config["application_stack"] // Deploy our app separately
    ]
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_linux_web_app.web_app.id
  subnet_id      = azurerm_subnet.app_service_plan.id
}

data "azurerm_log_analytics_workspace" "central" {
  name                = var.hub_law_name
  resource_group_name = var.hub_rg_name
}

resource "azurerm_application_insights" "web_insights" {
  name = "appi-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  workspace_id        = data.azurerm_log_analytics_workspace.central.id
  application_type    = "web"
}