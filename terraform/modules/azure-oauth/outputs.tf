output "client_id" {
  description = "Application (client) ID of the App Registration"
  value       = azuread_application.this.client_id
}

output "client_secret" {
  description = "Client secret value"
  value       = azuread_application_password.this.value
  sensitive   = true
}

output "tenant_id" {
  description = "Azure AD tenant ID"
  value       = var.tenant_id
}

output "identifier_uri" {
  description = "API identifier URI (derived from client_id)"
  value       = "api://${azuread_application.this.client_id}"
}

output "redirect_uris" {
  description = "Registered redirect URIs"
  value       = var.redirect_uris
}
