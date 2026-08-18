package mcp

import "core:encoding/base64"
import "core:encoding/json"
import "core:os"

Tool_Annotations :: struct {
  title:            Maybe(string) `json:"title,omitempty"`,
  read_only_hint:   Maybe(bool) `json:"readOnlyHint,omitempty"`,
  destructive_hint: Maybe(bool) `json:"destructiveHint,omitempty"`,
  idempotent_hint:  Maybe(bool) `json:"idempotentHint,omitempty"`,
  open_world_hint:  Maybe(bool) `json:"openWorldHint,omitempty"`,
}

// For tools with no parameters (not recommended - accepts any object)
Input_Schema_Empty_Object :: struct {
  type: string `json:"type"`, // "object"
}

// For tools with no parameters (recommended way - only accepts empty objects)
Input_Schema_Explicit_Empty_Object :: struct {
  using _:               Input_Schema_Empty_Object,
  additional_properties: bool `json:"additionalProperties"`,
}

// input schema MUST always be present - is required
Input_Schema :: union #no_nil {
  Input_Schema_Empty_Object,
  Input_Schema_Explicit_Empty_Object,
  json.Object,
}

Tool :: struct {
  // A tool name is unique in a MCP Server
  name:          string `json:"name"`,
  title:         Maybe(string) `json:"title,omitempty"`,
  description:   Maybe(string) `json:"description,omitempty"`,
  input_schema:  Input_Schema `json:"inputSchema"`,
  // Optional: defines expected output structure
  output_schema: Maybe(json.Object) `json:"outputSchema,omitempty"`,
  // Servers MUST consider this untrusted
  annotations:   Maybe(Tool_Annotations) `json:"annotations,omitempty"`,
  icons:         Maybe([]Icon) `json:"icons,omitempty"`,
  meta:          Maybe(json.Object) `json:"_meta,omitempty"`,
}

Tools_List_Response :: struct {
  result_type: string `json:"resultType"`,
  tools:       []Tool `json:"tools"`,
  next_cursor: Maybe(string) `json:"nextCursor,omitempty"`,
  ttl_ms:      Maybe(TTL_ms) `json:"ttlMs,omitempty"`,
  cache_scope: Maybe(string) `json:"cacheScope,omitempty"`,
}

Tools_Call_Request :: struct {
  meta:      Meta `json:"_meta"`,
  name:      string `json:"name"`,
  arguments: json.Value `json:"arguments,omitempty"`,
}

tools_call_validate :: proc(v: json.Value) -> (Tools_Call_Request, Error_Code) {
  bytes, _ := json.marshal(v, {}, context.allocator)

  req: Tools_Call_Request
  if json.unmarshal(bytes, &req, json.DEFAULT_SPECIFICATION, context.allocator) != nil {
    return {}, Error_Code.Invalid_Params
  }
  if req.name == "" do return {}, Error_Code.Invalid_Params
  return req, nil
}

// Decode a json.Value into a type T and validate that the
// `require`d fields are present
decode_and_require :: proc(args: json.Value, $T: typeid, required: []string) -> (T, Error_Code) {
  args_as_obj, is_args_obj := args.(json.Object)
  if !is_args_obj {
    return {}, Error_Code.Invalid_Params
  }

  for req in required {
    _, exists := args_as_obj[req]
    if !exists {
      return {}, Error_Code.Invalid_Params
    }
  }

  bytes, _ := json.marshal(args)

  res: T
  err := json.unmarshal(bytes, &res)
  if err != nil {
    return {}, Error_Code.Invalid_Params
  }

  return res, nil
}

Content_Type :: enum {
  Text,
  Image,
  Audio,
}

content_type_name :: proc(ct: Content_Type) -> string {
  switch ct {
  case Content_Type.Text:
    return "text"
  case Content_Type.Image:
    return "image"
  case Content_Type.Audio:
    return "audio"
  case:
    return ""
  }
}

Text_Content :: struct {
  type: string `json:"type"`, // "text"
  text: string `json:"text"`,
}

Media_Content :: struct {
  type:      string `json:"type"`, // "image" | "audio" etc
  data:      string `json:"data"`, // base64
  mime_type: string `json:"mimeType"`, // image/png, audio/wav etc
}

// Used for the Media_Content `data`
encode_base64 :: proc(file_path: string, allocator := context.allocator) -> string {
  bytes, _ := os.read_entire_file(file_path, allocator)
  data, _ := base64.encode(bytes, allocator = allocator)
  return data
}

Content_Block :: union {
  Text_Content,
  Media_Content,
}

validate_input_matches_input_schema :: proc(
  input: json.Value,
  $input_schema: typeid,
  required: []string,
) -> bool {
  _, err := decode_and_require(input, input_schema, required)

  if err != nil {
    return false
  }

  return true
}


build_successfull_tools_call_response :: proc(
  content: []Content_Block,
  structured_content: Maybe(json.Value),
) -> Tools_Call_Response {
  return Tools_Call_Response {
    result_type = result_type_name(Result_Type.Complete),
    is_error = false,
    content = content,
    structured_content = structured_content,
  }
}

build_failed_tools_call_response :: proc(
  content: []Content_Block,
  structured_content: Maybe(json.Value),
) -> Tools_Call_Response {
  return Tools_Call_Response {
    result_type = result_type_name(Result_Type.Complete),
    is_error = true,
    content = content,
    structured_content = structured_content,
  }
}

Tools_Call_Response :: struct {
  result_type:        string `json:"resultType"`,
  content:            []Content_Block `json:"content"`,
  // Required if the tool provides output_schema
  structured_content: Maybe(json.Value) `json:"structuredContent"`,
  is_error:           bool `json:"isError"`,
}

