package server

import jsonrpc "../jsonrpc"
import mcp "../mcp"
import "core:encoding/json"
import "core:fmt"

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

method_from_name :: proc(s: string) -> (mcp.Method, bool) {
  for m in mcp.Method {
    if mcp.method_name(m) == s do return m, true
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

  method, known := method_from_name(req.method)
  if !known {
    fmt.eprintfln("Method not recognised: %q", req.method)
    return nil
  }

  if req.id == nil {
    fmt.eprintln("request ID does not exist")
    // TODO: handle  notifications/progress and notifications/cancelled
    fmt.eprintln("will check for 'notifications/progress' OR 'notifications/cancelled'")
    return nil
  }

  // TODO: remove #partial once we have all methods implemented
  #partial switch method {
  case mcp.Method.Server_Discover:
    data := build_server_discover_response(s)
    return jsonrpc.create_result_response(data = data, id = jsonrpc_request_to_response_id(req.id))
  case:
    fmt.eprintfln("known method not implemented yet: %+v", method)
    return nil
  }
}

jsonrpc_request_to_response_id :: proc(rid: jsonrpc.Request_Id) -> jsonrpc.Response_Id {
  switch id in rid {
  case jsonrpc.ID:
    return id // string or i64 — pass through
  case json.Null:
    return nil // shouldn't reach a response
  }
  return nil
}

build_server_discover_response :: proc(s: ^Server) -> mcp.Server_Discover_Response {
  return mcp.Server_Discover_Response {
    result_type = mcp.result_type_name(mcp.Result_Type.Complete),
    supported_versions = mcp.SUPPORTED_VERSIONS,
    // TODO: improve this as we add more things
    capabilities = s.capabilities,
    meta = mcp.Server_Discover_Response_Meta{server_info = s.info},
    // 3 days
    ttl_ms = 60 * 60 * 24 * 3 * 1000,
    cache_scope = mcp.cache_scope_name(mcp.Cache_Scope.Public),
  }
}

