data "azurerm_container_registry" "devops" {
  name                = "acrglbuksdevopsutils"
  resource_group_name = local.hub_rg_name
}