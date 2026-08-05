package server

import jsonrpc "../jsonrpc"
import mcp "../mcp"
import "core:encoding/json"
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

  // We can only process methods that we know
  if !known {
    fmt.eprintfln("Method not recognised: %q", req.method)
    return nil
  }

  meta_err := validate_meta(req)
  if meta_err != nil {
    response_error := jsonrpc.Response_Error {
      code    = mcp.error_code_number(meta_err),
      message = mcp.error_code_message(meta_err),
    }
    return jsonrpc.create_error_response(
      error = response_error,
      id = jsonrpc.request_to_response_id(req.id),
    )
  }

  // TODO: check whether the request method requires a client capabilites. If the request doesn't have it,
  // then we return
  // missing required client capability for that method → -32021

  // Every request MUST have an ID. If not, we will handle it as a notification
  if req.id == nil {
    fmt.eprintln("request ID does not exist")
    // TODO: handle  notifications/progress and notifications/cancelled
    fmt.eprintln("will check for 'notifications/progress' OR 'notifications/cancelled'")
    return handle_notification(method, req, s)
  }

  return handle_request(method, req, s)
}

validate_meta :: proc(req: jsonrpc.JSONRPC_Request) -> mcp.Error_Code {
  if req.params == nil {
    fmt.eprintln("request doesn't have .params")
    return mcp.Error_Code.Invalid_Params
  }

  obj: json.Object = nil

  params_array, is_array := req.params.(json.Array)
  if is_array {
    for param in params_array {
      params_object, is_object := param.(json.Object)
      if !is_object do continue

      // we found an object, check if it has the "_meta"
      meta, ok := params_object["_meta"]
      if !ok do continue

      // we found the _meta one
      obj = params_object
    }

  } else {
    params_object, is_object := req.params.(json.Object)
    if !is_object {
      fmt.eprintln("params nor array nor object")
      return mcp.Error_Code.Invalid_Params
    }

    obj = params_object
  }

  if obj == nil {
    fmt.eprintln("params nor array nor object or we didn't find _meta in there")
    return mcp.Error_Code.Invalid_Params
  }

  meta, ok := obj["_meta"]
  if !ok {
    fmt.eprintln("meta does not exist in params")
    return mcp.Error_Code.Invalid_Params
  }

  // at this point we do have at least an object keyed by "_meta".
  meta_obj, is_meta_object := meta.(json.Object)
  if !is_meta_object {
    fmt.eprintln("meta is not an object")
    return mcp.Error_Code.Invalid_Params
  }

  // now, check for and required fields
  // 1. protocol version
  pv, has_pv := meta_obj[mcp.meta_field_name(mcp.Meta_Field.Protocol_Version)]
  if !has_pv {
    fmt.eprintln("_meta missing required protocol version")
    return mcp.Error_Code.Invalid_Params
  }
  protocol_version, is_pv_string := pv.(json.String)
  if !is_pv_string {
    fmt.eprintln("_meta protocol version is not a string")
    return mcp.Error_Code.Invalid_Params
  }
  if !slice.contains(mcp.SUPPORTED_VERSIONS, protocol_version) {
    fmt.eprintln("unsupported protocol version")
    return mcp.Error_Code.Unsupported_Protocol_Version
  }

  // 2. client capabilities
  cc, has_cc := meta_obj[mcp.meta_field_name(mcp.Meta_Field.Client_Capabilities)]
  if !has_cc {
    fmt.eprintln("_meta missing required client capabilities")
    return mcp.Error_Code.Invalid_Params
  }

  bytes, _ := json.marshal(cc, {}, context.allocator)
  client_capabilities: mcp.Client_Capabilities
  err := json.unmarshal(bytes, &client_capabilities)
  if err != nil {
    fmt.eprintln("client capabilities in wrong format (not mcp.Client_Capabilities)")
    return mcp.Error_Code.Invalid_Params
  }

  return nil
}

handle_request :: proc(
  method: mcp.Method,
  req: jsonrpc.JSONRPC_Request,
  s: ^Server,
) -> Maybe(jsonrpc.JSONRPC_Response) {

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

/*

  Notice that *ONLY* 'notifications/progress'  and 'notifications/cancelled'
  are both ways (client <-> server), so they are the ONLY ones that we could handle
  on a request in a MCP server.

*/
handle_notification :: proc(
  method: mcp.Method,
  req: jsonrpc.JSONRPC_Request,
  s: ^Server,
) -> Maybe(jsonrpc.JSONRPC_Response) {
  #partial switch method {
  case mcp.Method.Notifications_Progress:
    fmt.println("Need to implement 'notifications/progress'")
    return nil
  case mcp.Method.Notifications_Cancelled:
    fmt.println("Need to implement 'notifications/cancelled'")
    return nil
  case:
    fmt.eprintfln("notification not known or malformed: %+v", method)
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

