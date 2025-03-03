locals {
    mi_deployer_principal_name = "id-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-tf"
    postgres_assign_ad_role_script_path = "${path.module}/scripts/assign_ad_role.sql"
}


resource "terraform_data" "assign_fa_identity_role" {
  triggers_replace = timestamp()

  provisioner "local-exec" {
    command = <<EOT
      export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query "[accessToken]" -o tsv)
      psql -h ${data.terraform_remote_state.backend.outputs.postgres_fqdn} \
           -p 5432 -U ${local.mi_deployer_principal_name} \
           -d postgres -f ${local.postgres_assign_ad_role_script_path} \
           -v NOMAD_FUNCTION_APP_ADMIN_API="${azurerm_user_assigned_identity.fa_admin_api.name}" \
           -v NOMAD_FUNCTION_APP_JOB_ORCHESTRATOR="${azurerm_user_assigned_identity.fa_job_orchestrator.name}"
      EOT

      environment = {
        NOMAD_FUNCTION_APP_USER = azurerm_user_assigned_identity.fa_job_orchestrator.name
      }
  }
}