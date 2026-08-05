package server

import jsonrpc "../jsonrpc"
import mcp "../mcp"
import "core:fmt"
import "core:slice"

/*
  Decision layer for the MCP server. It's a request-in, response-out.
  Dispatch never stores anything (that's registry.odin responsibility)

  It handles things like:

  - id-presence rules (notification or just normal method)
  - lookups into registry
  - built-in methods
  - etc.
*/

// Called by the I/O loop at server.odin
dispatch :: proc(s: ^Server, req: jsonrpc.JSONRPC_Request) -> Maybe(jsonrpc.JSONRPC_Response) {
  method, known := mcp.method_from_name(req.method)
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
    return jsonrpc.create_result_response(data = data, id = jsonrpc.request_to_response_id(req.id))
  case mcp.Method.Tools_List:
    data := tools_list(s)
    return jsonrpc.create_result_response(data = data, id = jsonrpc.request_to_response_id(req.id))
  case:
    fmt.eprintfln("known method not implemented yet: %+v", method)
    return nil
  }
}

// Walk through the tools list in the server's registry
tools_list :: proc(s: ^Server) -> mcp.Tools_List_Response {
  tools, _ := slice.map_values(s.tools, context.allocator)
  // The spec wants this to be ordered
  slice.sort_by(tools, proc(a, b: mcp.Tool) -> bool {return a.name < b.name})

  return mcp.Tools_List_Response {
    result_type = mcp.result_type_name(mcp.Result_Type.Complete),
    tools       = tools,
    // 3 days
    ttl_ms      = 60 * 60 * 24 * 3 * 1000,
    cache_scope = mcp.cache_scope_name(mcp.Cache_Scope.Public),
  }
}

// Walk through the resources list in the server's registry
resources_list :: proc(s: ^Server) -> jsonrpc.JSONRPC_Response {
  unimplemented()
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

