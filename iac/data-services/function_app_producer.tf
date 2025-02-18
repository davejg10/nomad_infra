resource "azurerm_service_plan" "producer" {
  name                = "asp-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-producer"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  os_type             = "Linux"
  sku_name            = var.sku_name
}

resource "azurerm_role_assignment" "storage_roleassignment" {
  scope                = azurerm_storage_container.producer_container.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_linux_function_app.producer.identity[0].principal_id
}

resource "azurerm_storage_container" "producer_container" {
  name                  = var.producer_blob_container_name
  storage_account_id    = azurerm_storage_account.function_apps.id
  container_access_type = "private"
}

locals {
  blob_storage_container = "${azurerm_storage_account.function_apps.primary_blob_endpoint}${var.producer_blob_container_name}"
}

resource "azapi_resource" "producer" {
  type = "Microsoft.Web/sites@2023-12-01"
  schema_validation_enabled = false
  location = var.environment_settings.region
  name = "fa-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-producer"
  parent_id = data.azurerm_resource_group.rg.id

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "functionapp,linux",
    properties = {
      serverFarmId = azurerm_service_plan.producer.id,
        functionAppConfig = {
          deployment = {
            storage = {
              type = "blobContainer",
              value = local.blob_storage_container,
              authentication = {
                type = "SystemAssignedIdentity"
              }
            }
          },
          scaleAndConcurrency = {
            maximumInstanceCount = var.producer_max_instance_count,
            instanceMemoryMB     = var.producer_instance_memory
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
              value = azurerm_storage_account.function_apps.name
            }
          ]
        }
      }
  }

  lifecycle {
    ignore_changes = [
      body
    ]
  }
  
  depends_on = [ azurerm_service_plan.producer, azurerm_storage_account.function_apps ]
}

data "azurerm_linux_function_app" "producer" {
  name                = azapi_resource.producer.name
  resource_group_name = data.azurerm_resource_group.rg.name
}
