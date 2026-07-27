package jsonrpc

import "core:encoding/json"
import "core:fmt"

Response_Id :: union {
  string,
  i64,
}


FORBIDDEN_ERROR_CODES_RANGE: [2]i64 : {-32_768, -32_000}
is_error_code_in_forbidden_range :: proc(code: i64) -> bool {
  return code >= FORBIDDEN_ERROR_CODES_RANGE[0] && code <= FORBIDDEN_ERROR_CODES_RANGE[1]
}

// Error codes exceptions to the Forbidden Error Codes Range
// https://www.jsonrpc.org/specification?utm_source=chatgpt.com#:~:text=The%20error%20codes,rfc.fault_codes.php
explicit_error_code_message :: proc(code: i64) -> (message: string = "") {
  switch code {
  case -32700:
    message = "Parse error"
  case -32600:
    message = "Invalid Response"
  case -32601:
    message = "Method not found"
  case -32602:
    message = "Invalid params"
  case -32603:
    message = "Internal error"
  case -32099 ..= -32000:
    message = "Server error"
  }

  return message
}

is_error_code_valid :: proc(code: i64) -> bool {
  switch code {
  case -32700, -32600, -32601, -32602, -32603:
    return true
  case -32099 ..= -32000:
    return true
  case:
    return !is_error_code_in_forbidden_range(code)
  }
}

is_error_in_explicit_code_range :: proc(code: i64) -> bool {
  switch code {
  case -32700, -32600, -32601, -32602, -32603:
    return true
  case -32099 ..= -32000:
    return true
  case:
    return false
  }
}

Response_Error :: struct {
  // REQUIRED.
  // it needs to be valid (check `is_error_code_valid`)
  code:    i64,
  // REQUIRED
  // Short description of the error
  message: string,
  // Optional
  // This value is defined by the server, like detailed error info or nested errors
  data:    Maybe(json.Value),
}

JSONRPC_Response :: struct {
  // must be exactly "2.0"
  jsonrpc: string,

  // if success: REQUIRED
  // if error: MUST NOT exist
  // The value is determined by the method invoked
  result:  Maybe(json.Value),

  // if error: REQUIRED
  // if success: MUST NOT exist
  error:   Maybe(Response_Error),

  // REQUIRED. The same that was in the Response object
  id:      Response_Id,
}

Response_Parse_Error :: enum {
  Missing_JSONRPC_Version,
  Unsupported_JSONRPC_Version,
  Missing_Id,
  Forbidden_Error_Code,
  Result_Cannot_Exist_When_Error_And_Vice_Versa,
  Error_Struct_Invalid,
  Error_Message_Does_Not_Match_Explicit_Error_Code,
  Missing_Both_Result_And_Error,
}

JSONRPC_Response_Parse_Error :: union {
  json.Unmarshal_Error,
  Response_Parse_Error,
}

/*
  arena: virtual.Arena
  virtual.arena_init_growing(&arena)
  defer virtual.arena_destroy(&arena)
  req, err := jsonrpc.parse_response(line, virtual.arena_allocator(&arena)
*/
parse_response :: proc(
  data: []byte,
  allocator := context.allocator,
) -> (
  JSONRPC_Response,
  JSONRPC_Response_Parse_Error,
) {
  res: JSONRPC_Response

  err := json.unmarshal(data, &res, json.DEFAULT_SPECIFICATION, allocator)
  if err != nil {
    fmt.printfln("error while unmarshalling data.\nError: %v\nData: %q", err, data)
    return {}, err
  }

  if res.jsonrpc == "" {
    fmt.println("missing required field [jsonrpc]")
    return {}, Response_Parse_Error.Missing_JSONRPC_Version
  }

  if res.jsonrpc != JSONRPC_VERSION {
    fmt.printfln("unsupported JSON-RPC version: %s", res.jsonrpc)
    return {}, Response_Parse_Error.Unsupported_JSONRPC_Version
  }

  if res.id == "" || res.id == nil {
    fmt.println("missing required field [id]")
    return {}, Response_Parse_Error.Missing_Id
  }

  if res.result != nil && res.error != nil {
    fmt.println("error and result cannot be both set")
    return {}, Response_Parse_Error.Result_Cannot_Exist_When_Error_And_Vice_Versa
  }

  if res.result == nil && res.error == nil {
    fmt.println("error and result cannot be both nil")
    return {}, Response_Parse_Error.Missing_Both_Result_And_Error
  }

  if res.error != nil {
    error, ok := res.error.(Response_Error)
    if !ok {
      fmt.printfln("error struct is invalid: %+v", res.error)
      return {}, Response_Parse_Error.Error_Struct_Invalid
    }

    if !is_error_code_valid(error.code) {
      fmt.printfln("error code is not valid: %d", error.code)
      return {}, Response_Parse_Error.Forbidden_Error_Code
    }

    is_error_exception := is_error_in_explicit_code_range(error.code)
    expected_error_message := explicit_error_code_message(error.code)

    if is_error_exception &&
       (expected_error_message == "" || expected_error_message != error.message) {
      fmt.printfln("error code is not valid: %d", error.code)
      return {}, Response_Parse_Error.Error_Message_Does_Not_Match_Explicit_Error_Code

    }
  }

  return res, nil
}

