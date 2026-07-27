package jsonrpc

import "core:encoding/json"

FORBIDDEN_ERROR_CODES_RANGE: [2]i64 : {-32_768, -32_000}
is_error_code_in_forbidden_range :: proc(code: i64) -> bool {
  return code >= FORBIDDEN_ERROR_CODES_RANGE[0] && code <= FORBIDDEN_ERROR_CODES_RANGE[1]
}

Explicit_Error_Code :: enum i64 {
  Parse_Error      = -32700,
  Invalid_Request  = -32600,
  Method_Not_Found = -32601,
  Invalid_Params   = -32602,
  Internal_Error   = -32603,
  Server_Error_Min = -32099,
  Server_Error_Max = -32000,
}

// Error codes exceptions to the Forbidden Error Codes Range
// https://www.jsonrpc.org/specification?utm_source=chatgpt.com#:~:text=The%20error%20codes,rfc.fault_codes.php
explicit_error_code_message :: proc(code: i64) -> (message: string = "") {
  switch code {
  case i64(Explicit_Error_Code.Parse_Error):
    message = "Parse error"
  case i64(Explicit_Error_Code.Invalid_Request):
    message = "Invalid Request"
  case i64(Explicit_Error_Code.Method_Not_Found):
    message = "Method not found"
  case i64(Explicit_Error_Code.Invalid_Params):
    message = "Invalid params"
  case i64(Explicit_Error_Code.Internal_Error):
    message = "Internal error"
  case i64(Explicit_Error_Code.Server_Error_Min) ..= i64(Explicit_Error_Code.Server_Error_Max):
    message = "Server error"
  }

  return message
}

is_error_code_valid :: proc(code: i64) -> bool {
  switch code {
  case i64(Explicit_Error_Code.Parse_Error),
       i64(Explicit_Error_Code.Invalid_Request),
       i64(Explicit_Error_Code.Method_Not_Found),
       i64(Explicit_Error_Code.Invalid_Params),
       i64(Explicit_Error_Code.Internal_Error):
    return true
  case i64(Explicit_Error_Code.Server_Error_Min) ..= i64(Explicit_Error_Code.Server_Error_Max):
    return true
  case:
    return !is_error_code_in_forbidden_range(code)
  }
}

is_error_in_explicit_code_range :: proc(code: i64) -> bool {
  switch code {
  case i64(Explicit_Error_Code.Parse_Error),
       i64(Explicit_Error_Code.Invalid_Request),
       i64(Explicit_Error_Code.Method_Not_Found),
       i64(Explicit_Error_Code.Invalid_Params),
       i64(Explicit_Error_Code.Internal_Error):
    return true
  case i64(Explicit_Error_Code.Server_Error_Min) ..= i64(Explicit_Error_Code.Server_Error_Max):
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

