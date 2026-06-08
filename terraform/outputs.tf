output "client_id" {
  value = module.azure_oauth.client_id
}

output "client_secret" {
  value     = module.azure_oauth.client_secret
  sensitive = true
}

output "tenant_id" {
  value = module.azure_oauth.tenant_id
}

output "identifier_uri" {
  value = module.azure_oauth.identifier_uri
}

output "client_secret_uri" {
  description = "Key Vault URI for the client secret. Only set when key_vault_id is provided."
  value       = module.azure_oauth.client_secret_uri
}
