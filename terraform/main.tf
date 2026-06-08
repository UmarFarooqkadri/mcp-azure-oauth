terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "azure_oauth" {
  source = "./modules/azure-oauth"

  app_name              = var.app_name
  tenant_id             = var.tenant_id
  redirect_uris         = var.redirect_uris
  scopes                = var.scopes
  key_vault_id          = var.key_vault_id
  key_vault_secret_name = var.key_vault_secret_name
}
