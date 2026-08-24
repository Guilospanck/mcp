package mcp

// Uniquely identifies a resource
URI :: string

Resource :: struct {
  uri:         URI `json:"uri"`,
  name:        string `json:"name"`,
  title:       Maybe(string) `json:"title,omitempty"`,
  description: Maybe(string) `json:"description,omitempty"`,
  mime_type:   Maybe(string) `json:"mimeType,omitempty"`,
  size:        Maybe(i64) `json:"size,omitempty"`, // raw bytes size
  icons:       Maybe([]Icon) `json:"icons,omitempty"`,
  meta:        Maybe(Meta) `json:"_meta,omitempty"`,
  annotations: Maybe(Annotations) `json:"annotations,omitempty"`,
}

Resources_List_Response :: struct {
  result_type: string `json:"resultType"`,
  resources:   []Resource `json:"resources"`,
  next_cursor: Maybe(string) `json:"nextCursor,omitempty"`,
  using _:     Cache_Response_Fields,
}

Resources_Read_Request :: struct {
  uri: URI `json:"uri"`,
}

// This MUST only be used if the item can be represented as text
// (so it's not binary data)
Text_Resource_Contents :: struct {
  uri:       URI `json:"uri"`,
  mime_type: Maybe(string) `json:"mimeType,omitempty"`,
  text:      string `json:"text"`,
  meta:      Maybe(Meta) `json:"_meta,omitempty"`,
}

Blob_Resource_Contents :: struct {
  uri:       URI `json:"uri"`,
  mime_type: Maybe(string) `json:"mimeType,omitempty"`,
  blob:      string `json:"blob"`, // base64
  meta:      Maybe(Meta) `json:"_meta,omitempty"`,
}

Resources_Content :: union #no_nil {
  Text_Resource_Contents,
  Blob_Resource_Contents,
}

Resources_Read_Response :: struct {
  result_type: string `json:"resultType"`,
  contents:    []Resources_Content `json:"contents"`,
  using _:     Cache_Response_Fields,
}

