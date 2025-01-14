locals {
  private_dns_zones = {
    "vaultcore" = "privatelink.vaultcore.azure.net"
    "blob" = "privatelink.blob.core.windows.net",
    "acr" = "privatelink.azurecr.io"
    "monitor1" = "privatelink.agentsvc.azure-automation.net",
    "monitor2" = "privatelink.monitor.azure.com",
    "monitor3" = "privatelink.ods.opinsights.azure.com",
    "monitor4" = "privatelink.oms.opinsights.azure.com",
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "all_zones" {
  for_each = {
    for key, value in local.private_dns_zones : key => value
  }

  name                  = "${var.environment_settings.environment}-${each.key}-${var.environment_settings.app_name}"
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.all_zones[each.key].name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
