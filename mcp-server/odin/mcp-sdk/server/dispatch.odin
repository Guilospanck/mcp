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
  case mcp.Method.Tools_Call:
    data, err := tools_call(s, req)
    if err != nil {
      response_error := jsonrpc.Response_Error {
        code    = mcp.error_code_number(err),
        message = mcp.error_code_message(err),
      }
      return jsonrpc.create_error_response(
        error = response_error,
        id = jsonrpc.request_to_response_id(req.id),
      )
    }

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
    fmt.eprintln("Need to implement 'notifications/progress'")
    return nil
  case mcp.Method.Notifications_Cancelled:
    fmt.eprintln("Need to implement 'notifications/cancelled'")
    return nil
  case:
    fmt.eprintfln("notification not known or malformed: %+v", method)
    return nil
  }
}

// Walk through the tools list in the server's registry
tools_list :: proc(s: ^Server) -> mcp.Tools_List_Response {
  tools := make([]mcp.Tool, len(s.tools), context.allocator)

  i := 0
  for _, entry in s.tools {
    tools[i] = entry.info
    i += 1
  }

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

check_tools_call_input_valid :: proc(
  tools_call_req: mcp.Tools_Call_Request,
  tool_entry: Tool_Entry,
) -> Maybe(mcp.Error_Code) {
  input_schema := tool_entry.info.input_schema

  // If input states that it requires no parameters, then there's no input
  // to be validated
  _, is_explicit_no_param := input_schema.(mcp.Input_Schema_Explicit_Empty_Object)
  if is_explicit_no_param do return nil
  _, is_no_param := input_schema.(mcp.Input_Schema_Empty_Object)
  if is_no_param do return nil

  // check input schema is a json object
  input_schema_obj, input_schema_obj_exists := input_schema.(json.Object)
  if !input_schema_obj_exists do return mcp.Error_Code.Invalid_Params

  // check whether the key "properties" exists in that object
  input_schema_properties, input_schema_properties_exists := input_schema_obj["properties"]
  if !input_schema_properties_exists do return mcp.Error_Code.Invalid_Params

  // check whether the key "required" exists in that object
  input_schema_required, input_schema_required_exists := input_schema_obj["required"]

  if !input_schema_required_exists do return mcp.Error_Code.Invalid_Params

  // fill in "required" array
  required: [dynamic]string
  input_schema_required_array, is_array := input_schema_required.(json.Array)

  if is_array {
    for elm in input_schema_required_array {
      v, is_string := elm.(json.String)
      if !is_string {
        // The keys of properties MUST be string
        return mcp.Error_Code.Invalid_Params
      }
      append(&required, string(v))
    }
  }

  input_args := tools_call_req.arguments
  // INFO: this should be validating the actual type, but, as odin
  // doesn't yet have a lib for that (like zod) and I don't want to do it,
  // each MCP server implementation should check that.
  is_input_valid := mcp.validate_input_matches_input_schema(
    input_args,
    type_of(input_schema_properties),
    required[:],
  )
  if !is_input_valid do return mcp.Error_Code.Invalid_Params

  return nil
}

tools_call :: proc(
  s: ^Server,
  req: jsonrpc.JSONRPC_Request,
) -> (
  mcp.Tools_Call_Response,
  mcp.Error_Code,
) {
  // if the server doesn't allow tool calling, then return
  if s.capabilities.tools == nil {
    return {}, mcp.Error_Code.Method_Not_Found
  }

  // first validate that at least the shape of params is correct for a tools/call request.
  tools_call_req, tools_call_error := mcp.tools_call_validate(params_to_value(req.params))
  if tools_call_error != nil {
    return {}, tools_call_error
  }

  tool_name := tools_call_req.name

  // we can only call tools that the server has
  tool_entry, has_tool := s.tools[tool_name]
  if !has_tool {
    return {}, mcp.Error_Code.Invalid_Params
  }

  input_err := check_tools_call_input_valid(tools_call_req, tool_entry)
  if input_err != nil {
    return {}, mcp.Error_Code.Invalid_Params
  }

  // call the tool
  tools_call_res, tools_call_res_error := tool_entry.handler(req, tools_call_req.arguments)
  if tools_call_res_error != nil {
    return {}, tools_call_res_error
  }

  // validate that, should the tool have an outputSchema defined,
  // it also has the structuredContent in the response
  output_schema := tool_entry.info.output_schema
  if output_schema != nil && tools_call_res.structured_content == nil {
    fmt.eprintln("output schema was defined but no structuredContent in tools/call response")
    return {}, mcp.Error_Code.Invalid_Params
  }

  return tools_call_res, nil
}

add_tool :: proc(
  s: ^Server,
  info: mcp.Tool,
  handler: Tool_Handler,
) -> Maybe(jsonrpc.Response_Error) {
  _, tool_already_exists := s.tools[info.name]
  if tool_already_exists {
    return jsonrpc.Response_Error {
      code = i64(mcp.Error_Code.Invalid_Request),
      message = mcp.error_code_message(Error_Code.Invalid_Params),
      data = "Tool already exists",
    }
  }


  // set the server capabilities if unset
  if s.capabilities.tools == nil {
    s.capabilities.tools = mcp.Tools_Capab{}
  }

  s.tools[info.name] = {
    info    = info,
    handler = handler,
  }

  fmt.eprintfln("Saved %q tool", info.name)
  return nil
}

// Walk through the resources list in the server's registry
resources_list :: proc(s: ^Server) -> jsonrpc.JSONRPC_Response {
  unimplemented()
}

build_server_discover_response :: proc(s: ^Server) -> mcp.Server_Discover_Response {
  return mcp.Server_Discover_Response {
    result_type = mcp.result_type_name(mcp.Result_Type.Complete),
    supported_versions = mcp.SUPPORTED_VERSIONS,
    capabilities = s.capabilities,
    meta = mcp.Server_Discover_Response_Meta{server_info = s.info},
    // 3 days
    ttl_ms = 60 * 60 * 24 * 3 * 1000,
    cache_scope = mcp.cache_scope_name(mcp.Cache_Scope.Public),
  }
}

params_to_value :: proc(p: jsonrpc.Request_Params) -> json.Value {
  switch v in p {
  case json.Object:
    return v
  case json.Array:
    return v
  case:
    return nil
  }
}

