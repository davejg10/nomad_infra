environment_settings = {
  region         = "uksouth"
  region_code    = "uks"
  environment    = "dev"
  app_name       = "nomad"
  identifier     = "01"
}

// Networking
vnet_address_space = "10.0.0.0/25"
asp_subnet_address_prefixes = "10.0.0.0/27"
pe_subnet_address_prefixes = "10.0.0.32/28"
neo4j_subnet_address_prefixes = "10.0.0.48/28"

//NEO4J Virtual machine
neo4j_static_private_ip = "10.0.0.52"
neo4j_vm_size           = "Standard_B1s"

// App service
asp_sku_name = "B2"
exposed_container_port = 8080 //Tomcat webserver runs on port 8080

// Key Vault
key_vault_sku_name = "standard"
kv_purge_protection_enabled = "false"
kv_soft_delete_retention_days = 7
kv_public_network_access_enabled = false