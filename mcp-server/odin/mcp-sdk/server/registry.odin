/*
  Storage. Hold the tables and the API that the SDK's users call at startup
  Registry never reads a request.
*/
package server

import jsonrpc "../jsonrpc"
import mcp "../mcp"
import "core:encoding/json"

// Re-export so users can use
Server_Info :: mcp.Server_Info

Tools_Call_Response :: mcp.Tools_Call_Response
Text_Content :: mcp.Text_Content
Media_Content :: mcp.Media_Content
Content_Block :: mcp.Content_Block

build_successfull_tools_call_response :: mcp.build_successfull_tools_call_response
build_failed_tools_call_response :: mcp.build_failed_tools_call_response

Tool :: mcp.Tool
Tool_Input_Validator :: mcp.Tool_Input_Validator
make_input_validator :: mcp.make_input_validator

Error_Code :: mcp.Error_Code
decode_and_require :: mcp.decode_and_require

/**** TOOLS ****/
Tool_Handler :: #type proc(
  req: jsonrpc.JSONRPC_Request,
  args: json.Value,
) -> (
  mcp.Tools_Call_Response,
  mcp.Error_Code,
)

Tool_Name :: string

Tool_Entry :: struct {
  info:     mcp.Tool,
  handler:  Tool_Handler,
  validate: mcp.Tool_Input_Validator,
}

Server :: struct {
  info:         mcp.Server_Info,
  capabilities: mcp.Server_Capabilities,
  tools:        map[Tool_Name]Tool_Entry,
}

