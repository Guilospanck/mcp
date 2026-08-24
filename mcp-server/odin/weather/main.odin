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
    handler = mcp_sdk.make_handler(
      tools.Hello_Tool_Input,
      tools.Hello_Tool_Output,
      tools.hello_tool,
    ),
  )
  if error != nil {
    fmt.eprintfln("%+v", error)
    return
  }

  // resources
  my_resource := mcp_sdk.Resource {
    uri         = "file:///project/src/main.rs",
    name        = "main.rs",
    title       = "Rust Software Application Main File",
    description = "Primary application entry point",
    mime_type   = "text/x-rust",
  }

  mcp_sdk.add_resource(s = &server, info = my_resource)

  mcp_sdk.run(&server, .stdio)
}

