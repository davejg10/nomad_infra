resource "azurerm_service_plan" "consumer" {
  name                = "asp-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-consumer"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  os_type             = "Linux"
  sku_name            = var.consumer_sku_name
}

resource "azurerm_storage_account" "consumer" {
  name                     = "st${var.environment_settings.environment}${var.environment_settings.region_code}${var.environment_settings.app_name}${var.environment_settings.identifier}consumer"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = var.environment_settings.region
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny"
    ip_rules                   = ["82.133.78.250"]
    virtual_network_subnet_ids = [data.terraform_remote_state.backend.outputs.data_services_subnet_id]
  }
}

resource "azurerm_role_assignment" "consumer_to_package_storage" {
  scope                = azurerm_storage_container.consumer_container.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_linux_function_app.consumer.identity[0].principal_id
}

resource "azurerm_role_assignment" "consumer_to_app_key_vault" {
  scope                = data.terraform_remote_state.backend.outputs.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_linux_function_app.consumer.identity[0].principal_id
}

resource "azurerm_storage_container" "consumer_container" {
  name                  = var.consumer_blob_container_name
  storage_account_id    = azurerm_storage_account.consumer.id
  container_access_type = "private"
}

locals {
  consumer_blob_storage_container = "${azurerm_storage_account.consumer.primary_blob_endpoint}${var.consumer_blob_container_name}"
}

resource "azapi_resource" "consumer" {
  type = "Microsoft.Web/sites@2023-12-01"
  schema_validation_enabled = false
  location = var.environment_settings.region
  name = "fa-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-consumer"
  parent_id = data.azurerm_resource_group.rg.id

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "functionapp,linux",
    properties = {
      keyVaultReferenceIdentity = "SystemAssigned"
      serverFarmId = azurerm_service_plan.consumer.id,
        functionAppConfig = {
          deployment = {
            storage = {
              type = "blobContainer",
              value = local.consumer_blob_storage_container,
              authentication = {
                type = "SystemAssignedIdentity"
              }
            }
          },
          scaleAndConcurrency = {
            maximumInstanceCount = var.consumer_max_instance_count,
            instanceMemoryMB     = var.consumer_instance_memory
          },
          runtime = { 
            name = "java", 
            version = 17
          }
        },
        siteConfig = {
          appSettings = [
            {
              name = "AzureWebJobsStorage__accountName",
              value = azurerm_storage_account.consumer.name
            },
            # flexconsumption Function Apps cant use Key Vault reference so secrets must be fetched in code
            {
              name = "key_vault_uri",
              value = data.terraform_remote_state.backend.outputs.key_vault_uri
            },
            {
              name = "neo4j_uri",
              value = data.terraform_remote_state.backend.outputs.neo4j_uri
            },
            {
              name = "neo4j_user",
              value = data.terraform_remote_state.backend.outputs.neo4j_user
            },
            {
              name = "neo4j_password_key",
              value = data.terraform_remote_state.backend.outputs.neo4j_password_secret_key
            }
          ]
        }
      }
  }

  lifecycle {
    ignore_changes = [
      body,
      tags
    ]
  }
  
  depends_on = [ azurerm_service_plan.consumer, azurerm_storage_account.consumer ]
}

# The subnet is created in ../backend Terraform config directory
resource "azurerm_app_service_virtual_network_swift_connection" "consumer_vnet_integration" {
  app_service_id = data.azurerm_linux_function_app.consumer.id
  subnet_id      = data.terraform_remote_state.backend.outputs.data_services_subnet_id
}

data "azurerm_linux_function_app" "consumer" {
  name                = azapi_resource.consumer.name
  resource_group_name = data.azurerm_resource_group.rg.name
}
