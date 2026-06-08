terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azuread" {
  tenant_id = var.tenant_id
}

module "azure_oauth" {
  source = "./modules/azure-oauth"

  app_name      = var.app_name
  tenant_id     = var.tenant_id
  redirect_uris = var.redirect_uris
  scopes        = var.scopes
}
