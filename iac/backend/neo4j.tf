locals {
  neo4j_vm_name                 = "vm-dev-uks-nomad-neo4j-01"
  key_vault_network_script_path = "${path.module}/scripts/key_vault_network.sh"
}

resource "random_password" "neo4j_pwd" {
  length           = 12
  special          = true
  override_special = "_=+:?[]"
}

// Ensure we have network access before trying to insert secret
# resource "terraform_data" "kv_network_check" {
#   depends_on = [
#     azurerm_role_assignment.this_deployer_key_vault_secrets,
#   ]

#   triggers_replace = [
#     azurerm_private_endpoint.key_vault.id
#   ]

#   provisioner "local-exec" {
#     command = "chmod +x ${local.key_vault_network_script_path} && ./${local.key_vault_network_script_path}"

#     environment = {
#       KEY_VAULT_NAME        = azurerm_key_vault.nomad.name
#       KEY_VAULT_INTERNAL_IP = azurerm_private_endpoint.key_vault.private_service_connection[0].private_ip_address
#     }
#   }
# }

resource "azurerm_key_vault_secret" "neo4j_pwd" {
  # depends_on = [
  #   terraform_data.kv_network_check
  # ]

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
  name                 = "${local.neo4j_vm_name}-neo4j-datadisk"
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
    type = "SystemAssigned"
  }

}

locals {
  configure_script_name = "configure_vm.sh"
  templated_file = base64encode(templatefile("${path.module}/scripts/${local.configure_script_name}", {
    neo4j_version           = var.neo4j_version,
    neo4j_pass              = azurerm_key_vault_secret.neo4j_pwd.value,
    neo4j_data_disk_size_gb = var.neo4j_data_disk_size_gb,
  }))
  command_to_execute = jsonencode({
    commandToExecute = "echo ${local.templated_file} | base64 -d > ./${local.configure_script_name} && chmod +x ${local.configure_script_name} && ./${local.configure_script_name}"
  })
}

variable "vm_extension_replacement" {
  type    = number
  default = 1
}

resource "terraform_data" "vm_extension_replacement" {
  input = var.vm_extension_replacement
}

resource "azurerm_virtual_machine_extension" "configure_vm" {
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.neo4j
  ]

  lifecycle {
    replace_triggered_by = [
      azurerm_virtual_machine_data_disk_attachment.neo4j.id,
      terraform_data.vm_extension_replacement
    ]
  }

  name                 = "configure-vm" // Including the name here allows us to rebuild 
  virtual_machine_id   = azurerm_linux_virtual_machine.neo4j.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  protected_settings = local.command_to_execute
}

