# azure-oauth

Provisions an Azure AD App Registration for use with a FastMCP server secured by Azure OAuth 2.0. Creates the application, exposes configurable API permission scopes, registers a service principal, and generates a rotating client secret.

## Usage

```hcl
module "azure_oauth" {
  source = "./modules/azure-oauth"

  app_name  = "My MCP App"
  tenant_id = "00000000-0000-0000-0000-000000000000"
}
```

### Custom scopes and redirect URIs

```hcl
module "azure_oauth" {
  source = "./modules/azure-oauth"

  app_name  = "My MCP App"
  tenant_id = "00000000-0000-0000-0000-000000000000"

  redirect_uris = [
    "https://myapp.example.com/auth/callback",
    "http://localhost:50345/callback",
  ]

  scopes = [
    { value = "read",   description = "Read access to resources" },
    { value = "write",  description = "Write access to resources" },
    { value = "admin",  description = "Administrative access" },
  ]

  secret_expiry_months = 6
}
```

### Wiring outputs into FastMCP server.py

```hcl
resource "local_file" "server_config" {
  content = jsonencode({
    client_id     = module.azure_oauth.client_id
    client_secret = module.azure_oauth.client_secret
    tenant_id     = module.azure_oauth.tenant_id
    identifier_uri = module.azure_oauth.identifier_uri
  })
  filename = "${path.module}/server_config.json"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| hashicorp/azuread | ~> 2.0 |
| hashicorp/time | ~> 0.9 |
| hashicorp/random | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| azuread | ~> 2.0 |
| time | ~> 0.9 |
| random | >= 3.0 |

## Resources

| Name | Type |
|------|------|
| azuread_application.this | resource |
| azuread_application_password.this | resource |
| azuread_service_principal.this | resource |
| random_uuid.scope_id | resource |
| time_rotating.secret_expiry | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| app_name | Display name for the Azure App Registration | `string` | n/a | yes |
| tenant_id | Azure AD tenant ID | `string` | n/a | yes |
| redirect_uris | List of allowed OAuth redirect URIs | `list(string)` | `["http://localhost:8000/auth/callback", "http://localhost:50345/callback"]` | no |
| scopes | OAuth2 permission scopes to expose on the API. Each object requires a `value` (scope name) and `description`. | `list(object({ value = string, description = string }))` | `[{value="read", description="Read access"}, {value="write", description="Write access"}]` | no |
| secret_expiry_months | Number of months before the client secret rotates | `number` | `12` | no |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| client_id | Application (client) ID of the App Registration | no |
| client_secret | Client secret value | yes |
| tenant_id | Azure AD tenant ID | no |
| identifier_uri | API identifier URI derived from client_id (`api://<client_id>`) | no |
| redirect_uris | List of registered redirect URIs | no |

## Authentication

The module uses the `azuread` provider which authenticates via the Azure CLI by default. Run the following before `terraform apply`:

```bash
az login --tenant "<your-tenant-id>" --scope "https://graph.microsoft.com/.default"
```

For CI/CD pipelines, authenticate using a service principal with the following environment variables:

```bash
export ARM_CLIENT_ID="<service-principal-client-id>"
export ARM_CLIENT_SECRET="<service-principal-secret>"
export ARM_TENANT_ID="<tenant-id>"
```

## Notes

- The `client_secret` output is marked sensitive. Retrieve it with `terraform output -raw client_secret`.
- Scope IDs are stable random UUIDs generated once and stored in Terraform state. Changing a scope's `value` will destroy and recreate it.
- The client secret automatically rotates every `secret_expiry_months` months via `time_rotating`. After rotation, update your deployment with the new secret from `terraform output -raw client_secret`.
- The `identifier_uri` (`api://<client_id>`) matches the default FastMCP `AzureProvider` configuration and does not need to be set explicitly in `server.py` unless overridden.
