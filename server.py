import os
from fastmcp import FastMCP
from fastmcp.server.auth.providers.azure import AzureProvider

auth_provider = AzureProvider(
    client_id=os.environ["AZURE_CLIENT_ID"],
    client_secret=os.environ["AZURE_CLIENT_SECRET"],
    tenant_id=os.environ["AZURE_TENANT_ID"],
    base_url=os.getenv("BASE_URL", "http://localhost:8000"),
    required_scopes=os.getenv("AZURE_REQUIRED_SCOPES", "read,write").split(","),
)

mcp = FastMCP(name="Azure Secured App", auth=auth_provider)

@mcp.tool
async def get_user_info() -> dict:
    """Returns information about the authenticated Azure user."""
    from fastmcp.server.dependencies import get_access_token

    token = get_access_token()
    return {
        "azure_id": token.claims.get("sub"),
        "email": token.claims.get("email"),
        "name": token.claims.get("name"),
        "job_title": token.claims.get("job_title"),
        "office_location": token.claims.get("office_location")
    }
