package server_test

import "../../jsonrpc"
import "../../mcp"
import "../../server"
import "core:encoding/json"
import "core:testing"

common_response_result_test :: proc(
  t: ^testing.T,
  inputs: [][]byte,
  allocator := context.temp_allocator,
) -> (
  []byte,
  server.Server,
) {
  // Transport mock
  mock := mock_transport_create(inputs, allocator)
  defer mock.transport.close(&mock.transport)

  // Server with mocked transport
  srv := make_test_server()
  server.run_with_transport(&srv, &mock.transport)

  testing.expect_value(t, len(mock.outputs), 1)

  res, err := jsonrpc.parse_response(mock.outputs[:][0], allocator)

  testing.expect(t, err == nil)
  testing.expect_value(t, res.id, 1)
  testing.expect(t, res.error == nil)

  result := res.result
  testing.expect(t, result != nil)

  result_json, result_is_json := result.(json.Value)
  testing.expect_value(t, result_is_json, true)

  bytes, _ := json.marshal(result_json, {}, allocator)

  return bytes, srv
}

@(test)
should_call_server_discover :: proc(t: ^testing.T) {
  allocator := context.temp_allocator
  defer free_all(allocator)

  inputs := [][]byte {
    transmute([]byte)string(
      `{"jsonrpc":"2.0","id":1,"method":"server/discover","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientInfo":{"name":"example-client","version":"1.0.0"},"io.modelcontextprotocol/clientCapabilities":{"elicitation":{}}}}}`,
    ),
  }

  bytes, srv := common_response_result_test(t, inputs, allocator)

  parsed: mcp.Server_Discover_Response
  unmarshal_err := json.unmarshal(bytes, &parsed, json.DEFAULT_SPECIFICATION, allocator)
  testing.expect_value(t, unmarshal_err, nil)

  testing.expect_value(t, parsed.result_type, "complete")

  server_meta, is_server_meta := parsed.meta.server_info.(mcp.Server_Info)
  testing.expect_value(t, is_server_meta, true)

  testing.expect_value(t, server_meta.name, srv.info.name)
  testing.expect_value(t, server_meta.title, srv.info.title)
  testing.expect_value(t, server_meta.version, srv.info.version)
}

@(test)
should_call_tools_list :: proc(t: ^testing.T) {
  allocator := context.temp_allocator
  defer free_all(allocator)

  inputs := [][]byte {
    transmute([]byte)string(
      `{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{"cursor": "optional-cursor-value","_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientInfo":{"name":"example-client","version":"1.0.0"},"io.modelcontextprotocol/clientCapabilities":{"elicitation":{}}}}}`,
    ),
  }

  bytes, srv := common_response_result_test(t, inputs, allocator)

  parsed: mcp.Tools_List_Response
  unmarshal_err := json.unmarshal(bytes, &parsed, json.DEFAULT_SPECIFICATION, allocator)
  testing.expect_value(t, unmarshal_err, nil)

  testing.expect_value(t, parsed.result_type, "complete")
  testing.expect_value(t, len(parsed.tools), 0)
}

