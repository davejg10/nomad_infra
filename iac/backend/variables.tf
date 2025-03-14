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
variable "ghrunner_subnet_name" {
  type    = string
  default = "snt-ghrunners"
}

// Networking
variable "vnet_address_space" {
  type = string
}

variable "asp_subnet_address_prefixes" {
  type        = string
  description = "Address space for the subnet containing the Azure App Service."
}

variable "postgresql_subnet_address_prefixes" {
  type        = string
  description = "Address space for the subnet containing the PostgreSQL flexible server."
}

variable "neo4j_subnet_address_prefixes" {
  type        = string
  description = "Address space for the subnet containing the virtual machines hosting the neo4j databases."
}

variable "data_services_subnet_address_prefixes" {
  type        = string
  description = "Address space for the subnet the Azure Function Apps deployed in this configuration"
}

//NEO4J Virtual machine
variable "neo4j_static_private_ip" {
  type        = string
  description = "The static ip given to the network interface attached to the virtual machine hosting the neo4j database."
}
variable "neo4j_vm_size" {
  type        = string
  description = "Size of the VM hosting the neo4j database"
}

variable "neo4j_version" {
  type        = string
  description = "The version of neo4j installed in ./install_neo4j.sh script, which is run as a custom script extension"
}

variable "neo4j_user" {
  type        = string
  description = "The username created for the admin user of neo4j, passed into ./install_neo4j.sh script"
}

variable "neo4j_password_secret_key" {
  type        = string
  description = "The key for a secret in the Key Vault secret storing the Neo4j password"
}

variable "neo4j_data_disk_size_gb" {
  type        = string
  description = "Size in Gb of the data disk that will store the Neo4j data"
}

variable "backup_vault_rg_name" {
  type        = string
  description = "Name of the Resource Group containing the backup vault in this environment"
}

// Postgres
variable "postges_sku_name" {
  type = string
  description = "Name of the SKU to use for the PostgreSQL flexible server."
}

variable "postgres_backup_retention_days" {
  type = number
  description = "Number of days to keep backups for"
}

variable "postgres_storage_mb" {
  type = number
  description = "Size in MB of the Postgres disk"
}

variable "postgres_storage_tier" {
  type = string
  description = "Storage tier for the disk. Controls IOPS"
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

// Github federated credentials
variable "github_organisation_target" {
  type    = string
  default = "davejg10"
}

variable "github_repository_name" {
  type    = string
  default = "nomad_backend"
}