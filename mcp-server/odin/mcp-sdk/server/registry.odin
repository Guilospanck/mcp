/*

Storage. Hold the tables and the API that the SDK's users call at startup

Registry never reads a request.
*/
package server

import mcp "../mcp"

Server :: struct {
  info:         mcp.Server_Info,
  capabilities: mcp.Server_Capabilities,
}

