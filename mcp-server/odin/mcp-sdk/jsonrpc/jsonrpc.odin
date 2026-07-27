package jsonrpc

/*

  JSON-RPC allows you to perform RPC (Remote Procedure Call) via a JSON.

  It tells you "represent that function call as a JSON"

*/

JSONRPC_VERSION :: "2.0"

validate_response_match_request :: proc(req: JSONRPC_Request, res: JSONRPC_Response) -> bool {
  unimplemented()
}

