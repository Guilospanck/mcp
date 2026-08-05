package server_test

import mcp_sdk "../../mcp"
import "../../server"

make_test_server :: proc() -> server.Server {
  return server.Server {
    info = mcp_sdk.Server_Info {
      name = "dispatch_test_mcp_server",
      title = "Dispatch Test MCP Server",
      version = "0.0.1",
    },
  }
}

