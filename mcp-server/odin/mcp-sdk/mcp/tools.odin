package mcp

import "core:encoding/json"

Tool_Annotations :: struct {
  title:            Maybe(string) `json:"title,omitempty"`,
  read_only_hint:   Maybe(bool) `json:"readOnlyHint,omitempty"`,
  destructive_hint: Maybe(bool) `json:"destructiveHint,omitempty"`,
  idempotent_hint:  Maybe(bool) `json:"idempotentHint,omitempty"`,
  open_world_hint:  Maybe(bool) `json:"openWorldHint,omitempty"`,
}

Tool :: struct {
  // A tool name is unique in a MCP Server
  name:          string `json:"name"`,
  title:         Maybe(string) `json:"title,omitempty"`,
  description:   Maybe(string) `json:"description,omitempty"`,
  input_schema:  json.Object `json:"inputSchema"`,
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

