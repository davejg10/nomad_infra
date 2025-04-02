resource "azurerm_service_plan" "admin_api" {
  name                = "asp-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-admin-api"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  os_type             = "Linux"
  sku_name            = var.admin_api_sku_name
}

resource "azurerm_storage_account" "admin_api" {
  name                     = "st${var.environment_settings.environment}${var.environment_settings.region_code}adminapi"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = var.environment_settings.region
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [data.terraform_remote_state.backend.outputs.data_services_subnet_id]
  }
}

resource "azurerm_storage_container" "admin_api_container" {
  name                  = var.admin_api_blob_container_name
  storage_account_id    = azurerm_storage_account.admin_api.id
  container_access_type = "private"
}

locals {
  admin_api_blob_storage_container = "${azurerm_storage_account.admin_api.primary_blob_endpoint}${var.admin_api_blob_container_name}"
}

resource "azapi_resource" "function_app_admin_api" {
  type                      = "Microsoft.Web/sites@2023-12-01"
  schema_validation_enabled = false
  location                  = var.environment_settings.region
  name                      = "fa-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-admin-api"
  parent_id                 = data.azurerm_resource_group.rg.id

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.fa_admin_api.id]
  }

  body = {
    kind = "functionapp,linux",
    properties = {
      serverFarmId = azurerm_service_plan.admin_api.id,
      functionAppConfig = {
        deployment = {
          storage = {
            type  = "blobContainer",
            value = local.admin_api_blob_storage_container,
            authentication = {
              type = "UserAssignedIdentity",
              userAssignedIdentityResourceId = azurerm_user_assigned_identity.fa_admin_api.id
            }
          }
        },
        scaleAndConcurrency = {
          maximumInstanceCount = var.admin_api_max_instance_count,
          instanceMemoryMB     = var.admin_api_instance_memory
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
            value = azurerm_storage_account.admin_api.name
          },
          {
            name  = "APPLICATIONINSIGHTS_CONNECTION_STRING",
            value = data.terraform_remote_state.backend.outputs.app_insights_connection_string
          },
          {
            name  = "AZURE_CLIENT_ID",
            value = azurerm_user_assigned_identity.fa_admin_api.client_id
          },
          {
            name = "SPRING_PROFILE"
            value = "cloud"
          },
          # flexconsumption Function Apps cant use Key Vault reference so secrets must be fetched in code
          {
            name  = "KEY_VAULT_URI",
            value = data.terraform_remote_state.backend.outputs.key_vault_uri
          },
          {
            name  = "NEO4J_URI",
            value = data.terraform_remote_state.backend.outputs.neo4j_uri
          },
          {
            name  = "NEO4J_USER",
            value = data.terraform_remote_state.backend.outputs.neo4j_user
          },
          {
            name  = "NEO4J_PASSWORD_KEY",
            value = data.terraform_remote_state.backend.outputs.neo4j_password_secret_key
          },
          # Used to connect to PostgreSQl Flexible server using Managed Identity
          {
            name = "POSTGRES_URI"
            value = data.terraform_remote_state.backend.outputs.postgres_uri
          },
          {
            name = "FUNCTION_APP_MANAGED_IDENTITY_PRINCIPAL_NAME"
            value = azurerm_user_assigned_identity.fa_admin_api.name
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

  depends_on = [azurerm_service_plan.admin_api, azurerm_storage_account.admin_api]
}

data "azurerm_linux_function_app" "admin_api" {
  name                = azapi_resource.function_app_admin_api.name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# The subnet is created in ../backend Terraform config directory
resource "azurerm_app_service_virtual_network_swift_connection" "admin_api_vnet_integration" {
  app_service_id = data.azurerm_linux_function_app.admin_api.id
  subnet_id      = data.terraform_remote_state.backend.outputs.data_services_subnet_id
}