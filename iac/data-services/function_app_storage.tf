resource "azurerm_storage_account" "job_orchestrator" {
  name                     = "st${var.environment_settings.environment}${var.environment_settings.region_code}joborchestrator"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = var.environment_settings.region
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [data.terraform_remote_state.backend.outputs.data_services_subnet_id]
  }
}

locals {
  job_orchestrator_blob_storage_container = "${azurerm_storage_account.job_orchestrator.primary_blob_endpoint}${var.job_orchestrator_blob_container_name}"
}