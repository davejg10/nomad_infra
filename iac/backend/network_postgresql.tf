resource "azurerm_subnet" "postgresql" {
  name                 = "snt-postgresql"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.postgresql_subnet_address_prefixes]

  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_network_security_group" "postgresql_subnet" {
  name                = "nsg-postgresql-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
}
resource "azurerm_subnet_network_security_group_association" "postgresql_subnet" {
  subnet_id                 = azurerm_subnet.postgresql.id
  network_security_group_id = azurerm_network_security_group.postgresql_subnet.id
}

resource "azurerm_private_dns_zone" "postgresql" {
  name                = "nomad.${var.environment_settings.environment}.postgres.database.azure.com"
  resource_group_name   = data.azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres_this_vnet" {
  name                  = "${var.environment_settings.environment}-postgres-${var.environment_settings.app_name}"
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = data.azurerm_resource_group.rg.name

  depends_on            = [
    azurerm_subnet.postgresql,
    azurerm_virtual_network_peering.spoke_to_hub
  ]
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres_hub_vnet" {
  name                  = "${var.environment_settings.environment}-postgres-${var.environment_settings.app_name}"
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = data.azurerm_virtual_network.hub.id
  resource_group_name   = data.azurerm_resource_group.rg.name

  depends_on            = [
    azurerm_subnet.postgresql,
    azurerm_virtual_network_peering.hub_to_spoke
  ]
}