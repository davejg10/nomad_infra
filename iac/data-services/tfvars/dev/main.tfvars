environment_settings = {
  region      = "uksouth"
  region_code = "uks"
  environment = "dev"
  app_name    = "nomad"
  identifier  = "02"
}
// service bus
service_bus_local_auth = true

// job-orchestrator Function App
job_orchestrator_sku_name            = "FC1"
job_orchestrator_blob_container_name = "job-orchestrator-deployment-package"

// admin-api Function App
admin_api_sku_name            = "FC1"
admin_api_blob_container_name = "admin-api-deployment-package"

// Container app jobs
acr_namespace_name = "nomad-data"

// one2goasia
one_2_go_asia_job_cpu    = 0.5
one_2_go_asia_job_memory = "1Gi"
