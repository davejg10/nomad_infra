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

variable "resource_group_name" {
  type        = string
  description = "Passed in via Github Actions"
}

// Networking
variable "vnet_address_space" {
  type = string
}

variable "asp_subnet_address_prefixes" {
  type        = string
  description = "Address space for the subnet containing the Azure App Service."
}

variable "pe_subnet_address_prefixes" {
  type        = string
  description = "Address space for the subnet containing any private endpoints."
}

// App Service
variable "asp_sku_name" {
  type = string
}

variable "web_app_java_version" {
  type = string
}

// Key Vault
variable "key_vault_sku_name" {
  type = string
}

variable "kv_purge_protection_enabled" {
  type = string
}

variable "kv_soft_delete_retention_days" {
  type = number
}

variable "kv_public_network_access_enabled" {
  type = bool
}