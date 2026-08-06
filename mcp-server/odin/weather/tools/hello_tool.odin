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

hello_tool :: proc(
  req: jsonrpc.JSONRPC_Request,
  input: mcp_sdk.Tool_Arguments,
) -> (
  mcp_sdk.Tools_Call_Response,
  mcp_sdk.Error_Code,
) {

  fmt.eprintfln("%+v", req)
  v, err := mcp_sdk.decode_args(input, Hello_Tool_Input)
  if err != nil {
    return {}, err
  }

  fmt.eprintfln("HELLO: name=%s, age=%d, height=%d", v.name, v.age, v.height)

  return {}, nil
}

get_hello_tool_info :: proc() -> mcp_sdk.Tool {
  return mcp_sdk.Tool {
    name = "hello_tool",
    title = "Hello Tool",
    description = "Get hello from a tool",
    input_schema = get_hello_tool_schema(),
  }
}

@(private = "file")
get_hello_tool_schema :: proc() -> json.Value {
  schema := `{
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

  hello_tool_schema, _ := json.parse(transmute([]byte)schema)

  return hello_tool_schema
}

