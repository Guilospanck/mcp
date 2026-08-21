package mcp

import "core:encoding/json"

No_Schema :: struct {}

convert_schema_into_json_value :: proc(schema: any) -> ([]byte, json.Value, Error_Code) {

  schema_bytes, schema_marshal_err := json.marshal(schema)
  if schema_marshal_err != nil {
    return {}, {}, Error_Code.Invalid_Params
  }

  json_value_schema: json.Value
  schema_structured_err := json.unmarshal(schema_bytes, &json_value_schema)
  if schema_structured_err != nil {
    return {}, {}, Error_Code.Invalid_Params
  }

  return schema_bytes, json_value_schema, nil
}

