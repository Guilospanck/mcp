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
Input_Schema_With_Properties :: mcp.Input_Schema_With_Properties
Text_Content :: mcp.Text_Content
Media_Content :: mcp.Media_Content
Content_Block :: mcp.Content_Block
No_Schema :: mcp.No_Schema
URI :: mcp.URI
Resources_Content :: mcp.Resources_Content
Blob_Resource_Contents :: mcp.Blob_Resource_Contents
Text_Resource_Contents :: mcp.Text_Resource_Contents

build_successfull_tools_call_response :: mcp.build_successfull_tools_call_response
build_failed_tools_call_response :: mcp.build_failed_tools_call_response
convert_schema_into_json_value :: mcp.convert_schema_into_json_value
encode_base64 :: mcp.encode_base64

Tool :: mcp.Tool
Resource :: mcp.Resource

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
  info:    mcp.Tool,
  handler: Tool_Handler,
}
Tools :: map[Tool_Name]Tool_Entry

/**** RESOURCES ****/
Resource_Handler :: #type proc(
  uri: mcp.URI,
  allocator := context.allocator,
) -> (
  []mcp.Resources_Content,
  mcp.Error_Code,
)
Resource_Entry :: struct {
  info:    mcp.Resource,
  handler: Resource_Handler,
}
Resources :: map[mcp.URI]Resource_Entry

Resources_Templates :: map[mcp.URI]mcp.Resource_Template

/**** SERVER ****/
Server :: struct {
  info:                mcp.Server_Info,
  capabilities:        mcp.Server_Capabilities,
  tools:               Tools,
  resources:           Resources,
  resources_templates: Resources_Templates,
}

