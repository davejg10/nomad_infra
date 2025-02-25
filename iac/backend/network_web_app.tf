resource "azurerm_subnet" "app_service_plan" {
  name                 = "snt-app-service-plan"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.asp_subnet_address_prefixes]

  delegation {
    name = "appservice-delegation"

    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
        # "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_network_security_group" "app_service_plan_subnet" {
  name                = "nsg-asp-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
}
resource "azurerm_subnet_network_security_group_association" "app_service_plan_subnet" {
  subnet_id                 = azurerm_subnet.app_service_plan.id
  network_security_group_id = azurerm_network_security_group.app_service_plan_subnet.id
}
