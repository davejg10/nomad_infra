locals {

  script_name    = "install_neo4j.sh"
  templated_file = base64encode(templatefile("${path.module}/${local.script_name}"))
  command_to_execute = jsonencode({
    commandToExecute = "echo ${local.templated_file} | base64 -d > ./${local.script_name} && chmod +x ${local.script_name} && ./${local_script_name}"
  }

  neo4j_vm_name = "vm-dev-uks-nomad-neo4j-01"
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
  name                 = "${local.neo4j_vm_name}-disk1"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.environment_settings.region
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
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

# https://medium.com/neo4j/how-to-automate-neo4j-deploys-on-azure-d1eaeb15b70a
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

resource "azurerm_virtual_machine_extension" "example" {
  name                 = "hostname"
  virtual_machine_id   = azurerm_linux_virtual_machine.neo4j.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  protected_settings = local.command_to_execute
}