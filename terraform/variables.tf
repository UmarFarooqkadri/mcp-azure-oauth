variable "tenant_id" {
  description = "Azure AD tenant ID"
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
