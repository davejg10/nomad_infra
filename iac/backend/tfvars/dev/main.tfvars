environment_settings = {
  region      = "uksouth"
  region_code = "uks"
  environment = "dev"
  app_name    = "nomad"
  identifier  = "01"
}

// Networking
vnet_address_space                    = "10.0.0.0/25"
asp_subnet_address_prefixes           = "10.0.0.0/27"
postgresql_subnet_address_prefixes    = "10.0.0.32/28"
neo4j_subnet_address_prefixes         = "10.0.0.48/28"
data_services_subnet_address_prefixes = "10.0.0.64/26"

//NEO4J Virtual machine
neo4j_static_private_ip = "10.0.0.52"
neo4j_vm_size           = "Standard_B1ms"

neo4j_version             = "1:2025.01.0"
neo4j_user                = "neo4j"
neo4j_password_secret_key = "neo4j-password"
neo4j_data_disk_size_gb   = "10"

backup_vault_rg_name = "rg-dev-uks-backup"

// Postgres
postges_sku_name = "B_Standard_B1ms"
postgres_backup_retention_days = 7
postgres_storage_mb = 32768
postgres_storage_tier = "P10"
// App service
asp_sku_name           = "B1"
exposed_container_port = 8080 //Tomcat webserver runs on port 8080

// Key Vault
key_vault_sku_name               = "standard"
kv_purge_protection_enabled      = "false"
kv_soft_delete_retention_days    = 7
kv_public_network_access_enabled = true // Network ACLS