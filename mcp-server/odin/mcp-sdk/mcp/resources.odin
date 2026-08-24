package mcp

// Uniquely identifies a resource
URI :: string

Resource :: struct {
  uri:         URI `json:"uri"`,
  name:        string `json:"name"`,
  title:       string `json:"title"`,
  description: string `json:"description"`,
  mime_type:   string `json:"mimeType"`,
  icons:       Maybe([]Icon) `json:"icons,omitempty"`,
}


Resources_List_Response :: struct {
  result_type: string `json:"resultType"`,
  resources:   []Resource `json:"resources"`,
  next_cursor: Maybe(string) `json:"nextCursor,omitempty"`,
  using _:     Cache_Response_Fields,
}

