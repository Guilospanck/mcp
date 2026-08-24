package jsonrpc_test

import jsonrpc "../../jsonrpc"
import "core:encoding/json"
import "core:testing"

@(test)
response_should_parse_full_success_correctly :: proc(t: ^testing.T) {
  data := `{"jsonrpc": "2.0", "result": [10, 20, 30], "id": "potato-abc-de2" }`

  allocator := context.temp_allocator
  defer free_all(allocator)

  res, err := jsonrpc.parse_response(transmute([]byte)data, allocator)

  testing.expect_value(t, err, nil)
  testing.expect_value(t, res.jsonrpc, jsonrpc.JSONRPC_VERSION)
  testing.expect(t, res.id == "potato-abc-de2")

  result, ok := res.result.(json.Value).(json.Array)
  testing.expect_value(t, ok, true)

  testing.expect(t, len(result) == 3)
  testing.expect(t, result[0].(json.Integer) == 10)
  testing.expect(t, result[1].(json.Integer) == 20)
  testing.expect(t, result[2].(json.Integer) == 30)
}

@(test)
response_should_parse_full_error_correctly :: proc(t: ^testing.T) {
  data := `{"jsonrpc": "2.0", "error": {"code": 400, "message": "Great Success! NOT!", "data": {"info": "Yes, Great success. All good"}}, "id": "potato-abc-de2" }`

  allocator := context.temp_allocator
  defer free_all(allocator)

  res, err := jsonrpc.parse_response(transmute([]byte)data, allocator)

  testing.expect_value(t, err, nil)
  testing.expect_value(t, res.jsonrpc, jsonrpc.JSONRPC_VERSION)
  testing.expect(t, res.id == "potato-abc-de2")

  error, ok := res.error.(jsonrpc.Response_Error)
  testing.expect_value(t, ok, true)

  testing.expect(t, error.code == 400)
  testing.expect(t, error.message == "Great Success! NOT!")

  error_data, error_data_exist := error.data.(json.Value).(json.Object)
  testing.expect_value(t, error_data_exist, true)

  testing.expect(t, error_data["info"].(json.String) == "Yes, Great success. All good")
}

@(test)
response_should_not_parse_if_both_result_and_error_are_present :: proc(t: ^testing.T) {
  data := `{"jsonrpc": "2.0", "result": [10, 20, 30], "error": {"code": 400, "message": "Great Success! NOT!", "data": {"info": "Yes, Great success. All good"}}, "id": "potato-abc-de2"}`

  allocator := context.temp_allocator
  defer free_all(allocator)

  res, err := jsonrpc.parse_response(transmute([]byte)data, allocator)

  testing.expect(t, err != nil)
  testing.expect(
    t,
    err == jsonrpc.Response_Parse_Error.Result_Cannot_Exist_When_Error_And_Vice_Versa,
  )
}

@(test)
response_should_not_parse_if_both_result_and_error_are_missing :: proc(t: ^testing.T) {
  data := `{"jsonrpc": "2.0", "id": "potato-abc-de2"}`

  allocator := context.temp_allocator
  defer free_all(allocator)

  res, err := jsonrpc.parse_response(transmute([]byte)data, allocator)

  testing.expect(t, err != nil)
  testing.expect(t, err == jsonrpc.Response_Parse_Error.Missing_Both_Result_And_Error)
}

@(test)
response_should_not_parse_when_error_code_is_forbidden :: proc(t: ^testing.T) {
  data := `{"jsonrpc": "2.0", "error": {"code": -32768, "message": "Great Success! NOT!", "data": {"info": "Yes, Great success. All good"}}, "id": "potato-abc-de2" }`

  allocator := context.temp_allocator
  defer free_all(allocator)

  res, err := jsonrpc.parse_response(transmute([]byte)data, allocator)

  testing.expect(t, err != nil)
  testing.expect(t, err == jsonrpc.Response_Parse_Error.Forbidden_Error_Code)
}

@(test)
response_should_not_parse_when_error_message_from_explicit_code_is_not_match :: proc(
  t: ^testing.T,
) {
  data := `{"jsonrpc": "2.0", "error": {"code": -32700, "message": "Great Success! NOT!", "data": {"info": "Yes, Great success. All good"}}, "id": "potato-abc-de2" }`

  allocator := context.temp_allocator
  defer free_all(allocator)

  res, err := jsonrpc.parse_response(transmute([]byte)data, allocator)

  testing.expect(t, err != nil)
  testing.expect(
    t,
    err == jsonrpc.Response_Parse_Error.Error_Message_Does_Not_Match_Explicit_Error_Code,
  )
}

@(test)
response_should_not_parse_if_id_is_missing :: proc(t: ^testing.T) {
  data := `{"jsonrpc": "2.0", "error": {"code": 400, "message": "Great Success! NOT!", "data": {"info": "Yes, Great success. All good"}}}`

  allocator := context.temp_allocator
  defer free_all(allocator)

  res, err := jsonrpc.parse_response(transmute([]byte)data, allocator)

  testing.expect(t, err != nil)
  testing.expect(t, err == jsonrpc.Response_Parse_Error.Missing_Id)
}
//
response_should_not_parse_if_jsonrpc_is_missing :: proc(t: ^testing.T) {
  data := `{"error": {"code": 400, "message": "Great Success! NOT!", "data": {"info": "Yes, Great success. All good"}}, "id": "potato-abc-de2" }`

  allocator := context.temp_allocator
  defer free_all(allocator)

  res, err := jsonrpc.parse_response(transmute([]byte)data, allocator)

  testing.expect(t, err != nil)
  testing.expect(t, err == jsonrpc.Response_Parse_Error.Missing_JSONRPC_Version)
}

response_should_not_parse_if_jsonrpc_is_wrong :: proc(t: ^testing.T) {
  data := `{"jsonrpc": "1.0", "error": {"code": 400, "message": "Great Success! NOT!", "data": {"info": "Yes, Great success. All good"}}, "id": "potato-abc-de2" }`
  allocator := context.temp_allocator
  defer free_all(allocator)

  res, err := jsonrpc.parse_response(transmute([]byte)data, allocator)

  testing.expect(t, err != nil)
  testing.expect(t, err == jsonrpc.Response_Parse_Error.Unsupported_JSONRPC_Version)
}

