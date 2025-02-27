# This subnet hosts the Azure Function Apps deployed in ../data-services 
resource "azurerm_subnet" "data_services" {
  name                 = "snt-data-services"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.data_services_subnet_address_prefixes]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Sql"
  ]

  delegation {
    name = "appservice-delegation"

    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
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

output "data_services_subnet_id" {
  value = azurerm_subnet.data_services.id
}

output "data_services_subnet_address_prefix" {
  value = azurerm_subnet.data_services.address_prefixes[0]
}



