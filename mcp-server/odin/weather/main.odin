package weather_mcp_server

import mcp_sdk "../mcp-sdk/server"
import tools "./tools"
import "core:fmt"

main :: proc() {
  server := mcp_sdk.create_server(
    mcp_sdk.Server_Info {
      name = "weather-odin-mcp-server",
      title = "Weather MCP Server",
      version = "1.0.0",
    },
  )

  error := mcp_sdk.add_tool(&server, tools.get_hello_tool_info(), tools.hello_tool) // Hello tool
  if error != nil {
    fmt.eprintfln("%+v", error)
    return
  }

  mcp_sdk.run(&server, .stdio)
}

