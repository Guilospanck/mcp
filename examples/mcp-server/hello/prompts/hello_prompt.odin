package hello_prompts

import mcp_sdk "../../../../sdk/mcp"
import "core:fmt"

Hello_Prompt_Args :: struct {
  name: string,
}

get_hello_prompt :: proc(allocator := context.allocator) -> mcp_sdk.Prompt {
  arguments := make([]mcp_sdk.Prompt_Arguments, 1, allocator)
  arguments[0] = mcp_sdk.Prompt_Arguments {
    name        = "name",
    description = "The name to say hello to",
    required    = true,
  }

  return mcp_sdk.Prompt {
    name = "hello_prompt",
    title = "Hello prompt",
    description = "This is a hello prompt",
    arguments = arguments,
  }
}

hello_prompt_handler :: proc(
  args: Hello_Prompt_Args,
  allocator := context.allocator,
) -> (
  []mcp_sdk.Prompt_Message,
  mcp_sdk.Error_Code,
) {

  messages := make([dynamic]mcp_sdk.Prompt_Message, allocator)

  m1 := mcp_sdk.Prompt_Message {
    role = mcp_sdk.role_name(mcp_sdk.Role.Assistant),
    content = mcp_sdk.Text_Content{type = "text", text = "What is your name?"},
  }
  append(&messages, m1)

  m2 := mcp_sdk.Prompt_Message {
    role = mcp_sdk.role_name(mcp_sdk.Role.User),
    content = mcp_sdk.Text_Content{type = "text", text = fmt.tprintf("My name is %s", args.name)},
  }
  append(&messages, m2)

  m3 := mcp_sdk.Prompt_Message {
    role = mcp_sdk.role_name(mcp_sdk.Role.User),
    content = mcp_sdk.Media_Content {
      type = "image",
      data = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
      mime_type = "image/png",
    },
  }
  append(&messages, m3)

  return messages[:], nil

}
