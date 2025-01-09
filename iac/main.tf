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
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
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
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "azuread" {}

provider "github" {
  token = var.github_pat_token
  owner = var.github_organisation_target
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}