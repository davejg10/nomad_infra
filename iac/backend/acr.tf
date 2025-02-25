data "azurerm_container_registry" "devopsutils" {
  name                = var.hub_acr_name
  resource_group_name = var.hub_rg_name
}