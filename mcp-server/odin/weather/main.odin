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

  error := mcp_sdk.add_tool(
    s = &server,
    info = tools.get_hello_tool_info(),
    handler = mcp_sdk.make_handler(tools.Hello_Tool_Input, tools.hello_tool),
  )
  if error != nil {
    fmt.eprintfln("%+v", error)
    return
  }

  mcp_sdk.run(&server, .stdio)
}

