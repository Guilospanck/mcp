package hello_mcp_server

import mcp_sdk "../../../sdk/server"
import resources "./resources"
import tools "./tools"
import "core:fmt"

main :: proc() {
  server := mcp_sdk.create_server(
    mcp_sdk.Server_Info {
      name = "hello-odin-mcp-server",
      title = "Hello MCP Server",
      version = "1.0.0",
    },
  )

  // tools
  hello_tool_err := mcp_sdk.add_tool(
    s = &server,
    info = tools.get_hello_tool_info(),
    handler = mcp_sdk.make_tools_handler(
      tools.Hello_Tool_Input,
      tools.Hello_Tool_Output,
      tools.hello_tool,
    ),
  )
  if hello_tool_err != nil {
    fmt.eprintfln("%+v", hello_tool_err)
    return
  }

  // resources
  hello_resource_err := mcp_sdk.add_resource(
    s = &server,
    info = resources.get_hello_resource(),
    handler = resources.hello_resource_handler,
  )
  if hello_resource_err != nil {
    fmt.eprintfln("%+v", hello_resource_err)
    return
  }

  mcp_sdk.run(&server, .stdio)
}

