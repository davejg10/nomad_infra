resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"
  location            = var.environment_settings.region
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = [var.vnet_address_space]
}

data "azurerm_virtual_network" "hub" {
  name                = var.hub_vnet_name
  resource_group_name = var.hub_rg_name
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name = "hub-to-${var.environment_settings.environment}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"

  resource_group_name       = var.hub_rg_name
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name = "to-devopsutils"

  resource_group_name       = data.azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.hub.id
}
