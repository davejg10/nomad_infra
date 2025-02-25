locals {
  private_dns_zones = {
    "vaultcore" = "privatelink.vaultcore.azure.net"
    "blob"      = "privatelink.blob.core.windows.net",
    # "monitor1" = "privatelink.agentsvc.azure-automation.net", // Have commented the Azure Monitor private link scope in devops repo.
    # "monitor2" = "privatelink.monitor.azure.com", // for cost savings and saved complexity
    # "monitor3" = "privatelink.ods.opinsights.azure.com",
    # "monitor4" = "privatelink.oms.opinsights.azure.com",
  }
}

data "azurerm_private_dns_zone" "devopsutils" {
  for_each = {
    for key, value in local.private_dns_zones : key => value
  }

  name                = each.value
  resource_group_name = var.hub_rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "all_zones" {
  for_each = {
    for key, value in local.private_dns_zones : key => value
  }

  name                  = "${var.environment_settings.environment}-${each.key}-${var.environment_settings.app_name}"
  resource_group_name   = var.hub_rg_name
  private_dns_zone_name = data.azurerm_private_dns_zone.devopsutils[each.key].name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
