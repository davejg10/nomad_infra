locals {
  app_rg_name = "rg-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-01"
  app_vnet_name = "vnet-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-01"
}


resource "azurerm_subnet" "data_services" {
  name                 = "snt-data-services"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = local.app_vnet_name
  address_prefixes     = [var.data_services_subnet_address_prefixes]
}
resource "azurerm_network_security_group" "data_services_subnet" {
  name                = "nsg-data-services-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
}
resource "azurerm_subnet_network_security_group_association" "data_services" {
  subnet_id                 = azurerm_subnet.data_services.id
  network_security_group_id = azurerm_network_security_group.data_services_subnet.id
}