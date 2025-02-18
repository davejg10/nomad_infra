# Used to fetch the outputs from devopsutils statefile
data "terraform_remote_state" "backend" {
  backend = "azurerm"

  config = {
    use_oidc             = true
    resource_group_name  = "rg-${var.environment_settings.environment}-${var.environment_settings.region_code}-${var.environment_settings.app_name}-tf"

    storage_account_name = "st${var.environment_settings.environment}${var.environment_settings.region_code}${var.environment_settings.app_name}tf"
    container_name       = "nomad-backend"
    key                  = "nomad-backend.tfstate"
  }
}