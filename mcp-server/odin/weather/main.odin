package weather_mcp_server

import mcp_sdk "../mcp-sdk/server"

main :: proc() {
  server := mcp_sdk.Server {
    info = mcp_sdk.Server_Info {
      name = "weather-odin-mcp-server",
      title = "Weather MCP Server",
      version = "1.0.0",
    },
  }
  mcp_sdk.run(&server, .stdio)
}

