resource "azurerm_service_plan" "producer" {
  name                = "asp-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-producer"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  os_type             = "Linux"
  sku_name            = var.producer_sku_name
}

resource "azurerm_storage_account" "producer" {
  name                     = "st${var.environment_settings.environment}${var.environment_settings.region_code}${var.environment_settings.app_name}${var.environment_settings.identifier}producer"
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

resource "azurerm_role_assignment" "producer_to_package_storage" {
  scope                = azurerm_storage_account.producer.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_linux_function_app.producer.identity[0].principal_id
}

resource "azurerm_role_assignment" "producer_to_app_key_vault" {
  scope                = data.terraform_remote_state.backend.outputs.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_linux_function_app.producer.identity[0].principal_id
}

resource "azurerm_storage_container" "producer_container" {
  name                  = var.producer_blob_container_name
  storage_account_id    = azurerm_storage_account.producer.id
  container_access_type = "private"
}

locals {
  producer_blob_storage_container = "${azurerm_storage_account.producer.primary_blob_endpoint}${var.producer_blob_container_name}"
}

resource "azapi_resource" "producer" {
  type                      = "Microsoft.Web/sites@2023-12-01"
  schema_validation_enabled = false
  location                  = var.environment_settings.region
  name                      = "fa-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-producer"
  parent_id                 = data.azurerm_resource_group.rg.id

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
            type  = "blobContainer",
            value = local.producer_blob_storage_container,
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
          name    = "java",
          version = 17
        }
      },
      siteConfig = {
        appSettings = [
          {
            name  = "AzureWebJobsStorage__accountName",
            value = azurerm_storage_account.producer.name
          },
          {
            name  = "APPLICATIONINSIGHTS_CONNECTION_STRING",
            value = data.terraform_remote_state.backend.outputs.app_insights_connection_string
          },
          # flexconsumption Function Apps cant use Key Vault reference so secrets must be fetched in code
          {
            name  = "key_vault_uri",
            value = data.terraform_remote_state.backend.outputs.key_vault_uri
          },
          {
            name  = "neo4j_uri",
            value = data.terraform_remote_state.backend.outputs.neo4j_uri
          },
          {
            name  = "neo4j_user",
            value = data.terraform_remote_state.backend.outputs.neo4j_user
          },
          {
            name  = "neo4j_password_key",
            value = data.terraform_remote_state.backend.outputs.neo4j_password_secret_key
          },
          # Service Bus config
          {
            name  = "nomadservicebus__fullyQualifiedNamespace",
            value = "${azurerm_servicebus_namespace.nomad.name}.servicebus.windows.net"
          },
          {
            name  = "sb_pre_processed_queue_name",
            value = azurerm_servicebus_queue.pre_processed.name
          },
          {
            name  = "sb_processed_queue_name",
            value = azurerm_servicebus_queue.processed.name
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

  depends_on = [azurerm_service_plan.producer, azurerm_storage_account.producer]
}

# The subnet is created in ../backend Terraform config directory
resource "azurerm_app_service_virtual_network_swift_connection" "producer_vnet_integration" {
  app_service_id = data.azurerm_linux_function_app.producer.id
  subnet_id      = data.terraform_remote_state.backend.outputs.data_services_subnet_id
}

data "azurerm_linux_function_app" "producer" {
  name                = azapi_resource.producer.name
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "producer_servicebus_sender" {
  scope                = azurerm_servicebus_namespace.nomad.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = data.azurerm_linux_function_app.producer.identity[0].principal_id
}
resource "azurerm_role_assignment" "producer_servicebus_receiver" {
  scope                = azurerm_servicebus_namespace.nomad.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = data.azurerm_linux_function_app.producer.identity[0].principal_id
}
