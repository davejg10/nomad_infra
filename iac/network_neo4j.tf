resource "azurerm_subnet" "neo4j" {
  name                 = "snt-neo4j"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.neo4j_subnet_address_prefixes]
}