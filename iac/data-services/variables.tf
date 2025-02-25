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

<<<<<<< HEAD
// Hub config
variable "hub_rg_name" {
  type    = string
  default = "rg-glb-uks-devopsutils"
}
variable "hub_vnet_name" {
  type    = string
  default = "vnet-glb-uks-devopsutils"
}
variable "hub_acr_name" {
  type    = string
  default = "acrglbuksdevopsutils"
}
variable "hub_law_name" {
  type    = string
  default = "law-glb-uks-devopsutils"
}

// Producer Function App config
variable "producer_sku_name" {
  type        = string
=======
// Producer Function App config
variable "producer_sku_name" {
  type = string
>>>>>>> e188f34 (Added consumer infra)
  description = "The SKU used for the App Service Plan hosting the Function Apps"
}

variable "producer_blob_container_name" {
  type        = string
  description = "Name of the container created in the shared Storage Account that stores the deployment package"
}

variable "producer_max_instance_count" {
  default     = 40
  type        = number
  description = "Max number of instances of this Function. Min is 40"
}

variable "producer_instance_memory" {
  default     = 2048
  type        = number
  description = "Memory in MB for each instance."
}

// Container App Jobs
variable "acr_namespace_name" {
  type        = string
  description = "The name of the namespace in the central ACR that stores the images"
}

// one2goasia
variable "one_2_go_asia_job_cpu" {
  type        = number
  description = "Number of cores for the job"
}

variable "one_2_go_asia_job_memory" {
  type        = string
  description = "Number of Gb of memory. Suffixed with Gi"
}

// Github federated credentials
variable "github_organisation_target" {
  type    = string
  default = "davejg10"
}

variable "github_repository_name" {
  type    = string
  default = "nomad_data_services"
<<<<<<< HEAD
}
=======
}
>>>>>>> e188f34 (Added consumer infra)
