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
        name = "SPRING_PROFILE"
        value = "cloud"
      }
      env {
        name = "ENVIRONMENT"
        value = var.environment_settings.environment
      }
      env {
        name  = "SB_NAMESPACE_FQDN"
        value = "${azurerm_servicebus_namespace.nomad.name}.servicebus.windows.net"
      }
      env {
        name  = "SB_PRE_PROCESSED_QUEUE_NAME"
        value = azurerm_servicebus_queue.pre_processed.name
      }
      env {
        name  = "SB_PROCESSED_QUEUE_NAME"
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
      max_executions = "5"
      rules {
        name             = "azure-servicebus"
        custom_rule_type = "azure-servicebus"
        metadata = {
          "queueName"              = azurerm_servicebus_queue.pre_processed.name
          "namespace"              = azurerm_servicebus_namespace.nomad.name
          "messageCount"           = "20"
          "activationMessageCount" = "20"
        }
      }
    }
  }
}

//This block forces the below azapi_update_resource to be executed each time. 
// Otherwise after successive rebuilds we were losing the manged identity on the job
resource "terraform_data" "azapi_update_replacement" {
  triggers_replace = timestamp()
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