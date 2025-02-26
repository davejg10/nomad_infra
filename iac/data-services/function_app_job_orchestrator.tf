resource "azurerm_service_plan" "job_orchestrator" {
  name                = "asp-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-job-orchestrator"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  os_type             = "Linux"
  sku_name            = var.job_orchestrator_sku_name
}

resource "azurerm_storage_account" "job_orchestrator" {
  name                     = "st${var.environment_settings.environment}${var.environment_settings.region_code}${var.environment_settings.app_name}${var.environment_settings.identifier}job-orchestrator"
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

resource "azurerm_role_assignment" "job_orchestratorr_to_package_storage" {
  scope                = azurerm_storage_account.job_orchestrator.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_linux_function_app.job_orchestrator.identity[0].principal_id
}

resource "azurerm_role_assignment" "job_orchestrator_to_app_key_vault" {
  scope                = data.terraform_remote_state.backend.outputs.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_linux_function_app.job_orchestrator.identity[0].principal_id
}

resource "azurerm_storage_container" "job_orchestrator_container" {
  name                  = var.job_orchestrator_blob_container_name
  storage_account_id    = azurerm_storage_account.job_orchestrator.id
  container_access_type = "private"
}

locals {
  job_orchestrator_blob_storage_container = "${azurerm_storage_account.job_orchestrator.primary_blob_endpoint}${var.job_orchestrator_blob_container_name}"
}

resource "azapi_resource" "job_orchestrator" {
  type                      = "Microsoft.Web/sites@2023-12-01"
  schema_validation_enabled = false
  location                  = var.environment_settings.region
  name                      = "fa-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-job-orchestrator"
  parent_id                 = data.azurerm_resource_group.rg.id

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "functionapp,linux",
    properties = {
      serverFarmId = azurerm_service_plan.job_orchestrator.id,
      functionAppConfig = {
        deployment = {
          storage = {
            type  = "blobContainer",
            value = local.job_orchestrator_blob_storage_container,
            authentication = {
              type = "SystemAssignedIdentity"
            }
          }
        },
        scaleAndConcurrency = {
          maximumInstanceCount = var.job_orchestrator_max_instance_count,
          instanceMemoryMB     = var.job_orchestrator_instance_memory
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
            value = azurerm_storage_account.job_orchestrator.name
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

  depends_on = [azurerm_service_plan.job_orchestrator, azurerm_storage_account.job_orchestrator]
}

# The subnet is created in ../backend Terraform config directory
resource "azurerm_app_service_virtual_network_swift_connection" "job_orchestrator_vnet_integration" {
  app_service_id = data.azurerm_linux_function_app.job_orchestrator.id
  subnet_id      = data.terraform_remote_state.backend.outputs.data_services_subnet_id
}

data "azurerm_linux_function_app" "job_orchestrator" {
  name                = azapi_resource.job_orchestrator.name
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "job_orchestrator_servicebus_sender" {
  scope                = azurerm_servicebus_namespace.nomad.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = data.azurerm_linux_function_app.job_orchestrator.identity[0].principal_id
}
resource "azurerm_role_assignment" "job_orchestrator_servicebus_receiver" {
  scope                = azurerm_servicebus_namespace.nomad.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = data.azurerm_linux_function_app.job_orchestrator.identity[0].principal_id
}
