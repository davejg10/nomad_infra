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

variable "sku_name" {
  type = string
  description = "The SKU used for the App Service Plan hosting the Function Apps"
}