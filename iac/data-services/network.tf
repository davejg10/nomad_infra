resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_linux_web_app.producer.id
  subnet_id      = data.terraform_remote_state.devopsutils.outputs.data_services_subnet_id
}