# The subnet is created in ../backend Terraform config directory
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_linux_function_app.producer.id
  subnet_id      = data.terraform_remote_state.backend.outputs.data_services_subnet_id
}