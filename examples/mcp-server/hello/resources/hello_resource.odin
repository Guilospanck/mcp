package hello_resources

import mcp_sdk "../../mcp-sdk/server"
import "base:runtime"
import "core:path/filepath"

// dir of this .odin file, resolved at compile time
@(private = "file")
DIR :: #directory

get_hello_resource :: proc() -> mcp_sdk.Resource {
  return mcp_sdk.Resource {
    uri = "file://main.rs",
    name = "main.rs",
    title = "Rust Software Application Test Resource File",
    description = "Primary application entry point",
    mime_type = "text/x-rust",
  }
}

hello_resource_handler :: proc(
  uri: mcp_sdk.URI,
  allocator := context.allocator,
) -> (
  []mcp_sdk.Resources_Content,
  mcp_sdk.Error_Code,
) {
  contents := make([dynamic]mcp_sdk.Resources_Content, allocator)

  text_content := mcp_sdk.Text_Resource_Contents {
    uri       = uri,
    mime_type = "text/x-rust",
    text      = `fn main() {\n    println!(\“Hello world!\”);\n}`,
  }
  append(&contents, text_content)

  file_full_path, file_full_path_err := filepath.join({DIR, "./main.rs"}, allocator)
  if file_full_path_err != runtime.Allocator_Error.None {
    return {}, mcp_sdk.Error_Code.Internal_Error
  }

  blob_content := mcp_sdk.Blob_Resource_Contents {
    uri       = uri,
    mime_type = "text/x-rust",
    blob      = mcp_sdk.encode_base64(file_full_path, allocator),
  }
  append(&contents, blob_content)

  return contents[:], nil
}

