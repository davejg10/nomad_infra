environment_settings = {
  region      = "uksouth"
  region_code = "uks"
  environment = "dev"
  app_name    = "nomad"
  identifier  = "02"
}

// App Service Plan
job_orchestrator_sku_name            = "FC1"
job_orchestrator_blob_container_name = "job-orchestrator-deployment-package"

// Container app jobs
acr_namespace_name = "nomad-data"

// one2goasia
one_2_go_asia_job_cpu    = 2
one_2_go_asia_job_memory = "4Gi"
