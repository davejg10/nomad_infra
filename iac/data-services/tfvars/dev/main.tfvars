environment_settings = {
  region      = "uksouth"
  region_code = "uks"
  environment = "dev"
  app_name    = "nomad"
  identifier  = "02"
}

// App Service Plan
producer_sku_name            = "FC1"
producer_blob_container_name = "producer-deployment-package"

// Container app jobs
acr_namespace_name = "nomad-data"

// one2goasia
one_2_go_asia_job_cpu    = 0.5
one_2_go_asia_job_memory = "1Gi"
