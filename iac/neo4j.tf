locals {
  neo4j_vm_name = "vm-dev-uks-nomad-neo4j-01"
  key_vault_network_script_path = "${path.module}/scripts/key_vault_network.sh"
}

resource "random_password" "neo4j_pwd" {
  length           = 12
  special          = true
  override_special = "_=+:?[]"
}

// Ensure we have network access before trying to insert secret
resource "terraform_data" "kv_network_check" {
  depends_on = [
    azurerm_role_assignment.this_deployer_key_vault_secrets,
  ]
  
  triggers_replace = [
     azurerm_private_endpoint.key_vault.id
  ]

  provisioner "local-exec" {
    command = "chmod +x ${local.key_vault_network_script_path} && ./${local.key_vault_network_script_path}"

    environment = {
      KEY_VAULT_NAME = azurerm_key_vault.nomad.name
      KEY_VAULT_INTERNAL_IP = azurerm_private_endpoint.key_vault.ip_configuration[0].private_ip_address
    }
  }
}

resource "azurerm_key_vault_secret" "neo4j_pwd" {
  depends_on = [
    terraform_data.kv_network_check
  ]

  name         = "neo4j-password"
  value        = random_password.neo4j_pwd.result
  key_vault_id = azurerm_key_vault.nomad.id
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
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.neo4j_data_disk_size_gb
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
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
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
  mount_name_suffix = element(split("/", azurerm_virtual_machine_data_disk_attachment.neo4j.managed_disk_id), length(split("/", azurerm_virtual_machine_data_disk_attachment.neo4j.managed_disk_id)) - 1)


  neo4j_data_dir    = "/datadisk"
  mount_script_name = "mount_datadisk.sh"
  mount_templated_file = base64encode(templatefile("${path.module}/scripts/${local.mount_script_name}", {
    neo4j_data_disk_size_gb = var.neo4j_data_disk_size_gb,
    neo4j_data_dir          = local.neo4j_data_dir
  }))
  mount_command_to_execute = jsonencode({
    commandToExecute = "echo ${local.mount_templated_file} | base64 -d > ./${local.mount_script_name} && chmod +x ${local.mount_script_name} && ./${local.mount_script_name}"
  })
}

resource "azurerm_virtual_machine_extension" "mount_datadisk" {
  depends_on = [azurerm_virtual_machine_data_disk_attachment.neo4j]

  name                 = "mount-${local.mount_name_suffix}"
  virtual_machine_id   = azurerm_linux_virtual_machine.neo4j.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  protected_settings = local.mount_command_to_execute
}

locals {
  install_script_name    = "install_neo4j.sh"
  install_templated_file = base64encode(templatefile("${path.module}/scripts/${local.install_script_name}", {
    neo4j_version           = var.neo4j_version,
    neo4j_pass              = azurerm_key_vault_secret.neo4j_pwd.value,
    neo4j_data_dir          = local.neo4j_data_dir
  }))
  install_command_to_execute = jsonencode({
    commandToExecute = "echo ${local.install_templated_file} | base64 -d > ./${local.install_script_name} && chmod +x ${local.install_script_name} && ./${local.install_script_name}"
  })
}

resource "azurerm_virtual_machine_extension" "install_neo4j" {
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.neo4j,
    azurerm_virtual_machine_extension.mount_datadisk
  ]

  name                 = "install-neo4j"
  virtual_machine_id   = azurerm_linux_virtual_machine.neo4j.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  protected_settings = local.install_command_to_execute
}

