resource "azurerm_subnet" "private_endpoints" {
  name                 = "snt-private-endpoints"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.pe_subnet_address_prefixes]
}

resource "azurerm_network_security_group" "private_endpoints_subnet" {
  name                = "nsg-pe-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region

  security_rule {
    name                       = "AllowInternetHTTPs"
    priority                   = "110"
    direction                  = "Inbound"
    protocol                   = "Tcp"
    access                     = "Allow"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    destination_port_range     = "443"
    source_port_range          = "443"
    description                = "Allow HTTPs traffic from internet"
  }
}
resource "azurerm_subnet_network_security_group_association" "private_endpoints_subnet" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints_subnet.id
}