/*
  Storage. Hold the tables and the API that the SDK's users call at startup
  Registry never reads a request.
*/
package server

import jsonrpc "../jsonrpc"
import mcp "../mcp"

// Re-export so users can use
Server_Info :: mcp.Server_Info
Tools_Call_Response :: mcp.Tools_Call_Response
Tool :: mcp.Tool
Error_Code :: mcp.Error_Code
Tool_Arguments :: mcp.Arguments
decode_args :: mcp.decode_args

Tool_Callback :: proc(
  req: jsonrpc.JSONRPC_Request,
  args: mcp.Arguments,
) -> (
  mcp.Tools_Call_Response,
  mcp.Error_Code,
)


Tool_Entry :: struct {
  tool:     mcp.Tool,
  callback: Tool_Callback,
}

Server :: struct {
  info:         mcp.Server_Info,
  capabilities: mcp.Server_Capabilities,
  tools:        map[string]Tool_Entry,
}

