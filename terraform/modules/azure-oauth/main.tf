terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
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
