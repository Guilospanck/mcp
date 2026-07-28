package server

import jsonrpc "../jsonrpc"
import mcp_protocol "../mcp"

/*

  Decision layer for the MCP server. It's a request-in, response-out.

  Dispatch never stores anything (that's registry.odin responsibility)

  It handles things like:

  - lifecycle checks
  - id-presence rules (notification or just normal method)
  - lookups into registry
  - built-in methods
  - etc.

*/

method_from_name :: proc(s: string) -> (mcp_protocol.Method, bool) {
  for m in mcp_protocol.Method {
    if mcp_protocol.method_name(m) == s do return m, true
  }

  return {}, false
}

// Walk through the tools list in the server's registry
tools_list :: proc(s: ^Server) -> jsonrpc.JSONRPC_Response {
  unimplemented()
}

// Walk through the resources list in the server's registry
resources_list :: proc(s: ^Server) -> jsonrpc.JSONRPC_Response {
  unimplemented()
}

// Called by the I/O loop at server.odin
dispatch :: proc(s: ^Server, req: jsonrpc.JSONRPC_Request) -> Maybe(jsonrpc.JSONRPC_Response) {
  unimplemented()
}

