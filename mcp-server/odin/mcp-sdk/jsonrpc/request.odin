package jsonrpc

import "core:encoding/json"
import "core:fmt"
import "core:strings"

DISALLOWED_METHOD_PREFIX :: "rpc."

Request_Id :: union {
  json.Null,
  ID,
}

Request_Params :: union {
  json.Object,
  json.Array,
}

JSONRPC_Request :: struct {
  // must be exactly "2.0"
  jsonrpc: string,

  // name of the method to be invoked
  // methods that being with the word "rpc" followed by a period character
  // are reserved and MUST NOT be used for anything else
  method:  string,

  // if it exists, it MUST BE either null (SHOULD NOT normally be null) or string or number (SHOULD NOT be float)
  // if it is not included, it is considered a notification - and the server MUST NOT reply to it.
  // if included, the server MUST reply with the same value in the Response object
  id:      Request_Id,

  // it MAY be omitted.
  // it holds the parameter values to be used during the invocation of the method
  // it MUST be either json Array or json Object. the names of the parameters MUST
  // match exactly (case sensitive)
  params:  Request_Params,
}

Request_Parse_Error :: enum {
  Missing_JSONRPC_Version,
  Missing_Method,
  Unsupported_JSONRPC_Version,
  Method_Not_Allowed,
}

JSONRPC_Request_Parse_Error :: union {
  json.Unmarshal_Error,
  Request_Parse_Error,
}

/*
  arena: virtual.Arena
  virtual.arena_init_growing(&arena)
  defer virtual.arena_destroy(&arena)
  req, err := jsonrpc.parse_request(line, virtual.arena_allocator(&arena)
*/
parse_request :: proc(
  data: []byte,
  allocator := context.allocator,
) -> (
  JSONRPC_Request,
  JSONRPC_Request_Parse_Error,
) {
  req: JSONRPC_Request

  err := json.unmarshal(data, &req, json.DEFAULT_SPECIFICATION, allocator)
  if err != nil {
    fmt.printfln("error while unmarshalling data.\nError: %v\nData: %q", err, data)
    return {}, err
  }

  if req.jsonrpc == "" {
    fmt.println("missing required field [jsonrpc]")
    return {}, Request_Parse_Error.Missing_JSONRPC_Version
  }

  if req.method == "" {
    fmt.println("missing required field [method]")
    return {}, Request_Parse_Error.Missing_Method
  }

  if req.jsonrpc != JSONRPC_VERSION {
    fmt.printfln("unsupported JSON-RPC version: %s", req.jsonrpc)
    return {}, Request_Parse_Error.Unsupported_JSONRPC_Version
  }

  if strings.starts_with(req.method, DISALLOWED_METHOD_PREFIX) {
    fmt.printfln("method not allowed: %q", req.method)
    return {}, Request_Parse_Error.Method_Not_Allowed
  }

  return req, nil
}

