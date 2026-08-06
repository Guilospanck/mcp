package weather_mcp_server

import mcp_sdk "../mcp-sdk/server"
import tools "./tools"

main :: proc() {
  server := mcp_sdk.create_server(
    mcp_sdk.Server_Info {
      name = "weather-odin-mcp-server",
      title = "Weather MCP Server",
      version = "1.0.0",
    },
  )

  mcp_sdk.add_tool(&server, tools.get_hello_tool_info(), tools.hello_tool) // Hello tool

  mcp_sdk.run(&server, .stdio)
}

