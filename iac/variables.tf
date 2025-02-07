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
  type = string
  default = "rg-glb-uks-devopsutils"
}
variable "hub_vnet_name" {
  type = string
  default = "vnet-glb-uks-devopsutils"
}
variable "hub_acr_name" {
  type = string
  default = "acrglbuksdevopsutils"
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

variable "neo4j_subnet_address_prefixes" {
  type        = string
  description = "Address space for the subnet containing the virtual machines hosting the neo4j databases."
}

//NEO4J Virtual machine
variable "neo4j_static_private_ip" {
  type        = string
  description = "The static ip given to the network interface attached to the virtual machine hosting the neo4j database."
}


// App Service
variable "asp_sku_name" {
  type = string
}

variable "exposed_container_port" {
  type = number
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
