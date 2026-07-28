package mcp

/*

1. Requests

=> Unline JSON-RPC, the id of a request MUST NOT be null.
=> The request id MUST NOT have been previously used by the requestor within the same session

2. Responses

=> the id, when an error, MAY be optional in the cases of a parse error, for example.

3. Notifications

=> Are sent from client to server (or vice versa) as a one-way message (MUST NOT send a response)
=> MUST NOT include an ID

4. JSON schemas

=> Client and servers MUST support JSON Schema 2020-12 as default dialect
=> They also MUST validate schemas according to their declared (or default) dialect.
When they do not support a dialect, they MUST handle it gracefully, with an error indicating
that (instead of just breaking the application)
=> They SHOULD document which dialects they support.

*/


Method :: enum {
  Initialize,
  Ping,

  /* TOOLS */
  Tools_List,
  Tools_Call,

  /* RESOURCES */
  Resources_List,
  Resources_Read,
  Resources_Subscribe,
  Resources_Unsubscribe,
  Resources_Templates_List,

  /* PROMPTS */
  Prompts_List,
  Prompts_Get,

  /* COMPLETION */
  Completion_Complete,

  /* LOGGING */
  Logging_SetLevel,

  /* SAMPLING */
  Sampling_CreateMessage,

  /* ROOTS */
  Roots_List,

  /* NOTIFICATIONS */
  Notification_Initialized,
  Notification_Cancelled,
  Notification_Tools_List_Changed,
  Notification_Resources_List_Changed,
  Notification_Resources_Updated,
  Notification_Prompts_List_Changed,
  Notification_Logging_Message,
  Notification_Roots_List_Changed,
}

method_name :: proc(m: Method) -> string {
  switch m {
  case .Initialize:
    return "initialize"
  case .Ping:
    return "ping"
  case .Tools_List:
    return "tools/list"
  case .Tools_Call:
    return "tools/call"
  case .Resources_List:
    return "resources/list"
  case .Resources_Read:
    return "resources/read"
  case .Resources_Subscribe:
    return "resources/subscribe"
  case .Resources_Unsubscribe:
    return "resources/unsubscribe"
  case .Resources_Templates_List:
    return "resources/templates/list"
  case .Prompts_List:
    return "prompts/list"
  case .Prompts_Get:
    return "prompts/get"
  case .Completion_Complete:
    return "completion/complete"
  case .Logging_SetLevel:
    return "logging/setLevel"
  case .Sampling_CreateMessage:
    return "sampling/createMessage"
  case .Roots_List:
    return "roots/list"
  case .Notification_Initialized:
    return "notifications/initialized"
  case .Notification_Cancelled:
    return "notifications/cancelled"
  case .Notification_Tools_List_Changed:
    return "notifications/tools/list_changed"
  case .Notification_Resources_List_Changed:
    return "notifications/resources/list_changed"
  case .Notification_Resources_Updated:
    return "notifications/resources/updated"
  case .Notification_Prompts_List_Changed:
    return "notifications/prompts/list_changed"
  case .Notification_Logging_Message:
    return "notifications/message"
  case .Notification_Roots_List_Changed:
    return "notifications/roots/list_changed"
  }
  return ""
}

