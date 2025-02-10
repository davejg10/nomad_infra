resource "random_password" "neo4j_pwd" {
  length           = 12
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault_secret" "neo4j_pwd" {
  depends_on = [azurerm_role_assignment.this_deployer]

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

  script_name    = "install_neo4j.sh"
  templated_file = base64encode(templatefile("${path.module}/${local.script_name}", {
    neo4j_version           = var.neo4j_version,
    neo4j_pass              = azurerm_key_vault_secret.neo4j_pwd.value,
    neo4j_data_disk_size_gb = var.neo4j_data_disk_size_gb
    neo4j_snapshot_found    = local.neo4j_snapshot_found
  }))
  command_to_execute = jsonencode({
    commandToExecute = "echo ${local.templated_file} | base64 -d > ./${local.script_name} && chmod +x ${local.script_name} && ./${local.script_name}"
  })

  neo4j_vm_name = "vm-dev-uks-nomad-neo4j-01"
}

resource "azurerm_virtual_machine_extension" "install_neo4j" {
  depends_on = [azurerm_virtual_machine_data_disk_attachment.neo4j]

  name                 = "hostname"
  virtual_machine_id   = azurerm_linux_virtual_machine.neo4j.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  protected_settings = local.command_to_execute
}