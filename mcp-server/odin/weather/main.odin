package weather_mcp_server

import mcp_sdk "../mcp-sdk/server"

main :: proc() {
  server := mcp_sdk.Server{}
  mcp_sdk.run(&server, .stdio)
}

