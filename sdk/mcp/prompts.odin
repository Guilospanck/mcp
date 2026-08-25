package mcp

import "core:encoding/json"
Prompt_Arguments :: map[string]string

Input_Responses :: map[string]json.Value
Input_Requests :: map[string]json.Value

Prompt :: struct {
  name:        string `json:"name"`,
  title:       Maybe(string) `json:"title,omitempty"`,
  description: Maybe(string) `json:"description,omitempty"`,
  icons:       Maybe([]Icon) `json:"icons,omitempty"`,
  meta:        Maybe(Meta) `json:"_meta,omitempty"`,
}

Prompt_Message :: struct {
  role:    Role `json:"role"`,
  content: Content_Block `json:"content"`,
}

Prompts_List_Request :: struct {
  cursor: Maybe(Cursor) `json:"cursor,omitempty"`,
  meta:   Meta `json:"_meta,omitempty"`,
}

Prompts_List_Response :: struct {
  result_type: string `json:"resultType"`,
  prompts:     []Prompt `json:"prompts"`,
  next_cursor: Maybe(Cursor) `json:"nextCursor,omitempty"`,
  meta:        Maybe(Meta) `json:"_meta,omitempty"`,
  using _:     Cache_Response_Fields,
}

Prompt_Get_Request :: struct {
  meta:            Maybe(Meta) `json:"_meta,omitempty"`,
  input_responses: Maybe(Input_Responses) `json:"inputResponses,omitempty"`,
  request_state:   Maybe(string) `json:"requestState,omitempty"`,
  name:            string `json:"name"`,
  arguments:       Maybe(Prompt_Arguments) `json:"arguments,omitempty"`,
}

Prompt_Get_Result :: struct {
  meta:        Maybe(Meta) `json:"_meta,omitempty"`,
  result_type: string `json:"resultType"`,
  description: Maybe(string) `json:"description,omitempty"`,
  messages:    []Prompt_Message `json:"messages"`,
}

// At least one of `input_requests` or `request_state`
// MUST be present.
Input_Required_Result :: struct {
  meta:           Maybe(Meta) `json:"_meta,omitempty"`,
  result_type:    string `json:"resultType"`, // always "input_required"
  input_requests: Maybe(Input_Requests) `json:"inputRequests,omitempty"`,
  request_state:  Maybe(string) `json:"requestState,omitempty"`,
}

Prompt_Get_Response :: union #no_nil {
  Prompt_Get_Result,
  Input_Required_Result,
}

