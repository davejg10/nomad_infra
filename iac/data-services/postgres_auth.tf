locals {
    postgres_assign_ad_role_script_path = "${path.module}/scripts/assign_ad_role.sql"
}

resource "terraform_data" "assign_fa_identity_role" {
  provisioner "local-exec" {
    command = <<EOT
      export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query "[accessToken]" -o tsv)
      psql -h ${data.terraform_remote_state.backend.outputs.postgres_fqdn} -p 5432 -U ${data.azuread_user.current_user.user_principal_name} -d postgres -f ${local.postgres_assign_ad_role_script_path}
      EOT

      environment = {
        NOMAD_FUNCTION_APP_USER = azurerm_user_assigned_identity.job_orchestrator.name
      }
  }
}