// Assigned to the Neo4j virtual machine
resource "azurerm_user_assigned_identity" "neo4j" {
  name = "id-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-neo4j"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
}