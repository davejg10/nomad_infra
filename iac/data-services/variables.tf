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

variable "data_services_subnet_address_prefixes" {
  type        = string
  description = "Address space for the subnet the Azure Function Apps deployed in this configuration"
}

