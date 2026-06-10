# azure-oauth

Provisions an Azure AD App Registration for use with a FastMCP server secured by Azure OAuth 2.0. Creates the application, exposes configurable API permission scopes, registers a service principal, generates a rotating client secret, and optionally stores the secret in an existing Azure Key Vault.

## Usage

### Minimal

```hcl
module "azure_oauth" {
  source = "./modules/azure-oauth"

  app_name  = "My MCP App"
  tenant_id = "00000000-0000-0000-0000-000000000000"
}
```

### With Key Vault (recommended for production)

Create a Key Vault in your resource group first, then pass its resource ID:

```hcl
module "azure_oauth" {
  source = "./modules/azure-oauth"

  app_name     = "My MCP App"
  tenant_id    = "00000000-0000-0000-0000-000000000000"
  key_vault_id = "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<kv-name>"
}
```

The module will:
1. Assign "Key Vault Secrets Officer" to the identity running `terraform apply`
2. Store the client secret in the KV under the name set by `key_vault_secret_name` (default: `mcp-client-secret`)
3. Output the full KV secret URI as `client_secret_uri`

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
    { value = "read",  description = "Read access to resources" },
    { value = "write", description = "Write access to resources" },
    { value = "admin", description = "Administrative access" },
  ]

  secret_expiry_months = 6
}
```

### Wiring outputs into FastMCP server.py env vars

```hcl
environment_variables = {
  AZURE_CLIENT_ID     = module.azure_oauth.client_id
  AZURE_CLIENT_SECRET = module.azure_oauth.client_secret
  AZURE_TENANT_ID     = module.azure_oauth.tenant_id
  BASE_URL            = "https://${var.mcp_host}"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| hashicorp/azuread | ~> 2.0 |
| hashicorp/azurerm | ~> 3.0 |
| hashicorp/time | ~> 0.9 |
| hashicorp/random | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| azuread | ~> 2.0 |
| azurerm | ~> 3.0 |
| time | ~> 0.9 |
| random | >= 3.0 |

## Resources

| Name | Type |
|------|------|
| azuread_application.this | resource |
| azuread_application_password.this | resource |
| azurerm_key_vault_secret.client_secret | resource (conditional) |
| azurerm_role_assignment.kv_secrets_officer | resource (conditional) |
| random_uuid.scope_id | resource |
| time_rotating.secret_expiry | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| app_name | Display name for the Azure App Registration | `string` | n/a | yes |
| tenant_id | Azure AD tenant ID | `string` | n/a | yes |
| redirect_uris | List of allowed OAuth redirect URIs | `list(string)` | `["http://localhost:8000/auth/callback", "http://localhost:50345/callback"]` | no |
| scopes | OAuth2 permission scopes to expose on the API. Each object requires a `value` (scope name) and `description`. | `list(object({ value = string, description = string }))` | `[{value="read"}, {value="write"}]` | no |
| secret_expiry_months | Number of months before the client secret rotates | `number` | `12` | no |
| key_vault_id | Resource ID of an existing Key Vault to store the client secret. If null, the secret is only available as a sensitive Terraform output. | `string` | `null` | no |
| key_vault_secret_name | Name of the secret to create in the Key Vault | `string` | `"mcp-client-secret"` | no |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| client_id | Application (client) ID of the App Registration | no |
| client_secret | Client secret value. Only use when `key_vault_id` is not provided. | yes |
| client_secret_uri | Full Key Vault secret URI. Only set when `key_vault_id` is provided. | no |
| tenant_id | Azure AD tenant ID | no |
| identifier_uri | API identifier URI derived from client_id (`api://<client_id>`) | no |
| redirect_uris | List of registered redirect URIs | no |

## Authentication

The module uses the `azuread` and `azurerm` providers which authenticate via the Azure CLI by default. Run the following before `terraform apply`:

```bash
az login --tenant "<your-tenant-id>" --scope "https://graph.microsoft.com/.default"
```

For CI/CD pipelines, authenticate using a service principal:

```bash
export ARM_CLIENT_ID="<service-principal-client-id>"
export ARM_CLIENT_SECRET="<service-principal-secret>"
export ARM_TENANT_ID="<tenant-id>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
```

## Required Permissions

The identity running `terraform apply` (user or service principal) must have the following permissions. These have been tested and confirmed.

**Azure RBAC on the Resource Group containing the Key Vault:**

| Role | Purpose |
|---|---|
| `Contributor` | Create and manage resources in the RG |
| `User Access Administrator` | Assign "Key Vault Secrets Officer" to itself on the KV during apply |

Note: `User Access Administrator` at the RG level covers the KV automatically since the KV is inside the RG. No KV-specific role assignments are needed upfront.

**Microsoft Graph (Azure AD):**

| Permission | Type | Purpose |
|---|---|---|
| `Application.ReadWrite.OwnedBy` | Application | Create and manage App Registrations owned by the SP |

To grant Microsoft Graph permissions to a service principal via CLI:

```bash
# Add the permission
az ad app permission add \
  --id <sp-app-id> \
  --api 00000003-0000-0000-c000-000000000000 \
  --api-permissions 18a4783c-866b-4cc7-a460-3d5e5662c884=Role

# Grant admin consent
az ad app permission grant \
  --id <sp-app-id> \
  --api 00000003-0000-0000-c000-000000000000 \
  --scope "Application.ReadWrite.OwnedBy"
```

## Notes

- The `client_secret` output is marked sensitive. Retrieve it with `terraform output -raw client_secret`.
- When `key_vault_id` is provided, prefer using `client_secret_uri` over `client_secret` to avoid the raw secret being passed around.
- Scope IDs are stable random UUIDs generated once and stored in Terraform state. Changing a scope's `value` will destroy and recreate it.
- The client secret automatically rotates every `secret_expiry_months` months via `time_rotating`. After rotation, update your deployment with the new secret.
- The `identifier_uri` (`api://<client_id>`) matches the default FastMCP `AzureProvider` configuration and does not need to be set explicitly in `server.py` unless overridden.
- When `key_vault_id` is provided, the module assigns "Key Vault Secrets Officer" to the identity running `terraform apply`. For a dedicated Terraform SP, this role is assigned automatically.

## Not yet parameterized

The following are hardcoded to sensible defaults but can be extended if your use case requires it:

| Property | Hardcoded value | When to change |
|---|---|---|
| `sign_in_audience` | `AzureADMyOrg` (single tenant) | Set to `AzureADMultipleOrgs` for multi-tenant apps. Note: requires destroy and recreate of the App Registration. |
| `type` per scope | `User` | Change to `Admin` for scopes that should require admin consent rather than user consent. |
| `identifier_uri` | `api://<client_id>` | Override if you need a vanity URI such as `api://myapp.example.com`. |
| `requested_access_token_version` | `2` | No reason to change this for modern Azure AD applications. |
| `secret_reader_object_ids` | not implemented | Add to assign "Key Vault Secrets User" to specific SPs or users that need to read the secret at runtime (e.g. MCP server managed identity). |
