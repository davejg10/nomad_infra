# Environment instance specific settings object
variable "environment_settings" {
  type = object({
    region      = string
    region_code = string
    environment = string
    app_name    = string
    identifier  = string
  })
}

// Producer Function App config
variable "producer_sku_name" {
  type = string
  description = "The SKU used for the App Service Plan hosting the Function Apps"
}

variable "producer_blob_container_name" {
  type = string
  description = "Name of the container created in the shared Storage Account that stores the deployment package"
}

variable "producer_max_instance_count" {
  default = 40
  type = number
  description = "Max number of instances of this Function. Min is 40"
}

variable "producer_instance_memory" {
  default = 2048
  type = number
  description = "Memory in MB for each instance."
}

// Consumer Function App config
variable "consumer_sku_name" {
  type = string
  description = "The SKU used for the App Service Plan hosting the Function Apps"
}

variable "consumer_blob_container_name" {
  type = string
  description = "Name of the container created in the shared Storage Account that stores the deployment package"
}

variable "consumer_max_instance_count" {
  default = 40
  type = number
  description = "Max number of instances of this Function. Min is 40"
}

variable "consumer_instance_memory" {
  default = 2048
  type = number
  description = "Memory in MB for each instance."
}

// Github federated credentials
variable "github_organisation_target" {
  type    = string
  default = "davejg10"
}

variable "github_repository_name" {
  type    = string
  default = "nomad_data_services"
}