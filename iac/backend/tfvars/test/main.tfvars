environment_settings = {
  region         = "uksouth"
  region_code    = "uks"
  environment    = "test"
  app_name       = "nomad"
  identifier     = "01"
}

// Networking
vnet_address_space = "10.0.0.128/25"
asp_subnet_address_prefixes = "10.0.0.128/27"
pe_subnet_address_prefixes = "10.0.0.160/28"

// App service
asp_sku_name = "B2"
exposed_container_port = 8080 //Tomcat webserver runs on port 8080

// Key Vault
key_vault_sku_name = "standard"
kv_purge_protection_enabled = "false"
kv_soft_delete_retention_days = 7
kv_public_network_access_enabled = false