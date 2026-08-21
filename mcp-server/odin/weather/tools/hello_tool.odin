package weather_tools

import jsonrpc "../../mcp-sdk/jsonrpc"
import mcp_sdk "../../mcp-sdk/server"
import "core:encoding/json"
import "core:fmt"

Hello_Tool_Input :: struct {
  name:   string,
  age:    int,
  height: Maybe(int),
}

Hello_Tool_Output :: struct {
  name:   string,
  age:    int,
  height: Maybe(int),
}

hello_tool :: proc(
  req: jsonrpc.JSONRPC_Request,
  input: Hello_Tool_Input,
) -> (
  mcp_sdk.Tools_Call_Response,
  mcp_sdk.Error_Code,
) {
  fmt.eprintfln("%+v", req)

  fmt.eprintfln("HELLO: name=%s, age=%d, height=%d", input.name, input.age, input.height)

  output: Hello_Tool_Output = {
    name   = input.name,
    age    = input.age,
    height = input.height,
  }

  output_bytes, output_json_value, output_json_value_err := mcp_sdk.convert_schema_into_json_value(
    output,
  )
  if output_json_value_err != nil {
    fmt.eprintln("error converting ouput schema from [hello_tool] into bytes/json.Value")
    return {}, mcp_sdk.Error_Code.Invalid_Params

  }

  // For backwards compatibility, a tool that returns structured content SHOULD also return the serialized JSON in a TextContent block.
  // NOTE: heap-allocate the slice so it outlives this proc; a slice literal
  // would live on the stack and dangle once we return `res`.
  content := make([]mcp_sdk.Content_Block, 1)
  content[0] = mcp_sdk.Text_Content {
    type = "text",
    text = transmute(string)(output_bytes),
  }

  res := mcp_sdk.build_successfull_tools_call_response(
    content = content,
    structured_content = output_json_value,
  )

  return res, nil
}

get_hello_tool_info :: proc() -> mcp_sdk.Tool {
  input, output := get_hello_tool_schema()
  return mcp_sdk.Tool {
    name = "hello_tool",
    title = "Hello Tool",
    description = "Get hello from a tool",
    input_schema = input,
    output_schema = output,
  }
}

@(private = "file")
get_hello_tool_schema :: proc() -> (input: json.Object, output: json.Object) {
  input_schema := `{
      "type": "object",
      "properties": {
        "name": {
          "type": "string",
          "description": "Your name",
        },
        "age": {
          "type": "integer",
          "description": "Your age",
        },
        "height": {
          "type": "integer",
          "description": "Your height",
        }
      },
      "required": ["name", "age"]
    }`

  _ = json.unmarshal(transmute([]byte)input_schema, &input)

  output_schema := `{
      "type": "object",
      "properties": {
        "name": {
          "type": "string",
          "description": "Your name",
        },
        "age": {
          "type": "integer",
          "description": "Your age",
        },
        "height": {
          "type": "integer",
          "description": "Your height",
        }
      },
      "required": ["name", "age"]
  }`

  _ = json.unmarshal(transmute([]byte)output_schema, &output)

  return
}

