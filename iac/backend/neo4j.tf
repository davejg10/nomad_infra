locals {
  neo4j_vm_name                 = "vm-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-${var.environment_settings.identifier}-neo4j"
}

resource "random_password" "neo4j_pwd" {
  length           = 12
  special          = true
  override_special = "_=+:?[]"
}

resource "azurerm_key_vault_secret" "neo4j_pwd" {
  name         = var.neo4j_password_secret_key
  value        = random_password.neo4j_pwd.result
  key_vault_id = azurerm_key_vault.nomad.id
}

// These are each used in the Function Apps to connect to the Database
output "neo4j_user" {
  value = var.neo4j_user
}
output "neo4j_uri" {
  value = "bolt://${var.neo4j_static_private_ip}:7687"
}
output "neo4j_password_secret_key" {
  value = var.neo4j_password_secret_key
}

resource "azurerm_public_ip" "example" {
  name                = "test-publicip"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "neo4j" {
  name                = "${local.neo4j_vm_name}-nic-01"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region

  ip_configuration {
    name                          = "linux"
    subnet_id                     = azurerm_subnet.neo4j.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.neo4j_static_private_ip
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_managed_disk" "neo4j" {
  name                 = "${local.neo4j_vm_name}-datadisk"
  resource_group_name  = data.azurerm_resource_group.rg.name
  location             = var.environment_settings.region
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.neo4j_data_disk_size_gb

  lifecycle {
    ignore_changes = [ // If we ever restore from backup, and import we dont want the disk to be re-created next time we plan/apply
      create_option,
      source_resource_id,
      name,
      zone
    ]
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "neo4j" {
  managed_disk_id    = azurerm_managed_disk.neo4j.id
  virtual_machine_id = azurerm_linux_virtual_machine.neo4j.id
  lun                = "10"
  caching            = "ReadWrite"
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "azurerm_linux_virtual_machine" "neo4j" {
  name                  = local.neo4j_vm_name
  resource_group_name   = data.azurerm_resource_group.rg.name
  location              = var.environment_settings.region
  network_interface_ids = [azurerm_network_interface.neo4j.id]
  computer_name         = "neo4j"
  size                  = var.neo4j_vm_size
  admin_username        = "azureuser"

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.neo4j.id]
  }

}