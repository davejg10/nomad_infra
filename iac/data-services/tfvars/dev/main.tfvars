environment_settings = {
  region         = "uksouth"
  region_code    = "uks"
  environment    = "dev"
  app_name       = "nomad"
  identifier     = "02"
}

// App Service Plan

consumer_sku_name = "FC1"
producer_sku_name = "FC1"

producer_blob_container_name = "producer-deployment-package"
consumer_blob_container_name = "consumer-deployment-package"