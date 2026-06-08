from fastmcp import Client
from fastmcp.client.auth import OAuth
import asyncio

async def main():
    auth = OAuth(callback_port=50345)
    async with Client("http://localhost:8000/mcp", auth=auth) as client:
        # First-time connection will open Azure login in your browser
        print("✓ Authenticated with Azure!")
        
        # Test the protected tool
        result = await client.call_tool("get_user_info")
        data = result.content[0].text if result.content else str(result)
        print(f"Result: {data}")

if __name__ == "__main__":
    asyncio.run(main())