resource "azurerm_container_app_environment" "scrapers" {
  name = "acae-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-scrapers"

  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = var.environment_settings.region
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.central.id

  infrastructure_resource_group_name = "acae-managed-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-scrapers"
  infrastructure_subnet_id           = data.terraform_remote_state.backend.outputs.data_services_subnet_id

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  # internal_load_balancer_enabled = true
}

data "azurerm_log_analytics_workspace" "central" {
  name                = var.hub_law_name
  resource_group_name = var.hub_rg_name
}