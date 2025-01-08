terraform {
  backend "azurerm" {
    use_oidc = true
    key      = "nomad-backend.tfstate"
  }
}

terraform {
  required_version = ">= 1.3.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.14.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.30.0"
    }

  }
}

provider "azurerm" {
  use_oidc                        = true
  resource_provider_registrations = "core"

  resource_providers_to_register = [
    # "Microsoft.ContainerService",
    # "Microsoft.KeyVault",
  ]

  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = false
    }
  }
}

provider "azuread" {}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}