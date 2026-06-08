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
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

locals {
  scope_ids = { for s in var.scopes : s.value => random_uuid.scope_id[s.value].result }
}

resource "random_uuid" "scope_id" {
  for_each = { for s in var.scopes : s.value => s }
}

resource "azuread_application" "this" {
  display_name = var.app_name

  web {
    redirect_uris = var.redirect_uris
  }

  api {
    requested_access_token_version = 2

    dynamic "oauth2_permission_scope" {
      for_each = { for s in var.scopes : s.value => s }
      content {
        id                         = local.scope_ids[oauth2_permission_scope.key]
        value                      = oauth2_permission_scope.value.value
        user_consent_description   = oauth2_permission_scope.value.description
        user_consent_display_name  = oauth2_permission_scope.value.value
        admin_consent_description  = oauth2_permission_scope.value.description
        admin_consent_display_name = oauth2_permission_scope.value.value
        enabled                    = true
        type                       = "User"
      }
    }
  }
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
}

resource "time_rotating" "secret_expiry" {
  rotation_months = var.secret_expiry_months
}

resource "azuread_application_password" "this" {
  application_id = azuread_application.this.id
  rotate_when_changed = {
    rotation = time_rotating.secret_expiry.id
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "kv_secrets_officer" {
  count                = var.key_vault_id != null ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "client_secret" {
  count        = var.key_vault_id != null ? 1 : 0
  name         = var.key_vault_secret_name
  value        = azuread_application_password.this.value
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_role_assignment.kv_secrets_officer]
}
