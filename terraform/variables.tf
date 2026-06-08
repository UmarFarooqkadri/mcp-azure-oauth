variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "app_name" {
  description = "Display name for the App Registration"
  type        = string
  default     = "Azure Secured App"
}

variable "redirect_uris" {
  description = "OAuth redirect URIs"
  type        = list(string)
  default     = [
    "http://localhost:8000/auth/callback",
    "http://localhost:50345/callback",
  ]
}

variable "scopes" {
  description = "OAuth2 permission scopes"
  type = list(object({
    value       = string
    description = string
  }))
  default = [
    { value = "read",  description = "Read access" },
    { value = "write", description = "Write access" },
  ]
}

variable "key_vault_id" {
  description = "Resource ID of an existing Key Vault to store the client secret. If null, the secret is only available as a sensitive Terraform output."
  type        = string
  default     = null
}

variable "key_vault_secret_name" {
  description = "Name of the secret to create in the Key Vault"
  type        = string
  default     = "mcp-client-secret"
}
