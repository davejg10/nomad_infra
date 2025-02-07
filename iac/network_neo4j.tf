resource "azurerm_subnet" "neo4j" {
  name                 = "snt-neo4j"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.neo4j_subnet_address_prefixes]
}
resource "azurerm_network_security_group" "neo4j_subnet" {
  name                = "nsg-neo4j-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
}
resource "azurerm_subnet_network_security_group_association" "neo4j_subnet" {
  subnet_id                 = azurerm_subnet.neo4j.id
  network_security_group_id = azurerm_network_security_group.neo4j.id
}