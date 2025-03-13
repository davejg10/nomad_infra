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

