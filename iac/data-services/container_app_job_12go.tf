resource "azurerm_user_assigned_identity" "one2goasia" {
  name = "id-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-acaj"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
}

resource "azurerm_role_assignment" "one2goasia_job_pull_acr" {
  scope                = data.azurerm_container_registry.devopsutils.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.one2goasia.principal_id
}

resource "azurerm_role_assignment" "consumer_servicebus_sender" {
  scope                = azurerm_servicebus_namespace.nomad.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_user_assigned_identity.one2goasia.principal_id
}
resource "azurerm_role_assignment" "consumer_servicebus_receiver" {
  scope                = azurerm_servicebus_namespace.nomad.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_user_assigned_identity.one2goasia.principal_id
}

resource "azurerm_container_app_job" "one2goasia" {
  name = "aca-${var.environment_settings.environment}-${var.environment_settings.region_code}-one2goasia"

  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = var.environment_settings.region
  container_app_environment_id = azurerm_container_app_environment.scrapers.id
  replica_timeout_in_seconds   = 1800

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.one2goasia.id]
  }

  registry {
    server   = data.azurerm_container_registry.devopsutils.login_server
    identity = azurerm_user_assigned_identity.one2goasia.id
  }

  template {
    container {
      name   = "onetogoasia-scraper"
      image  = "${data.azurerm_container_registry.devopsutils.login_server}/${var.acr_namespace_name}/one2goasia:latest"
      cpu    = var.one_2_go_asia_job_cpu
      memory = var.one_2_go_asia_job_memory

      env {
        name  = "sb_namespace_fqdn"
        value = "${azurerm_servicebus_namespace.nomad.name}.servicebus.windows.net"
      }
      env {
        name  = "sb_pre_processed_queue_name"
        value = azurerm_servicebus_queue.pre_processed.name
      }
      env {
        name  = "sb_processed_queue_name"
        value = azurerm_servicebus_queue.processed.name
      }
      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.one2goasia.client_id
      }
    }
  }

  event_trigger_config {
    scale {
      max_executions = "3"
      rules {
        name             = "azure-servicebus"
        custom_rule_type = "azure-servicebus"
        metadata = {
          "queueName"              = azurerm_servicebus_queue.pre_processed.name
          "namespace"              = azurerm_servicebus_namespace.nomad.name
          "messageCount"           = "5"
        }
      }
    }
  }
}

resource "terraform_data" "azapi_update_replacement" {
  triggers_replaces = timestamp()
}


// Terraform provider doesnt allow you to use pod managed identity to authenticate with Azure Service Bus event scaler
resource "azapi_update_resource" "service_bus_scale" {
  type        = "Microsoft.App/jobs@2024-02-02-preview"
  resource_id = azurerm_container_app_job.one2goasia.id

  body = {
    properties = {
      configuration = {
        eventTriggerConfig = {
          scale = {
            rules = [
              {
                name     = "azure-servicebus"
                type     = "azure-servicebus"
                identity = azurerm_user_assigned_identity.one2goasia.id
              }
            ]
          }
        }
      }

    }
  }
  lifecycle {
    replace_triggered_by = [
      terraform_data.azapi_update_replacement
    ]
  }
  

  depends_on = [
    azurerm_container_app_job.one2goasia,
  ]
}