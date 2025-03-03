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

// Job Orchestrator Function App config
variable "job_orchestrator_sku_name" {
  type        = string
  description = "The SKU used for the App Service Plan hosting the Function Apps"
}

variable "job_orchestrator_blob_container_name" {
  type        = string
  description = "Name of the container created in the Storage Account used by the job-orchestrator Function App. It stores the deployment package"
}

variable "job_orchestrator_max_instance_count" {
  default     = 40
  type        = number
  description = "Max number of instances of this Function. Min is 40"
}

variable "job_orchestrator_instance_memory" {
  default     = 2048
  type        = number
  description = "Memory in MB for each instance."
}

// Admin api Function App config
variable "admin_api_sku_name" {
  type        = string
  description = "The SKU used for the App Service Plan hosting the Function Apps"
}

variable "admin_api_blob_container_name" {
  type = string
  description = "name of the container created in the Storage Account used by the admin-api Function App. It stores the deployment package."
}

variable "admin_api_max_instance_count" {
  default     = 40
  type        = number
  description = "Max number of instances of this Function. Min is 40"
}

variable "admin_api_instance_memory" {
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
}
