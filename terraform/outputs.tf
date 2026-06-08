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
