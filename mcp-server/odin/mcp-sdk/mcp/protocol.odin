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
  /****** Client -> Server (request) ******/

  // Discover server identity & capabilities
  Server_Discover,
  // List available tools
  Tools_List,
  // Execute a tool
  Tools_Call,
  // List resources
  Resources_List,
  // List resource templates
  Resources_Templates_List,
  // Read a resource
  Resources_Read,
  // Subscribe to resource change streams
  Subscriptions_Listen,
  // List prompts
  Prompts_List,
  // Get a prompt
  Prompts_Get,
  // Argument completion
  Completion_Complete,

  /****** Server -> Client (request) ******/

  // Request user input (MRTR pattern)
  Elicitation_Create,

  /****** Notifications (one-way, no response) ******/

  // Server announces tool list changed
  Notifications_Tools_List_Changed,
  // Server announces resource list changed
  Notifications_Resources_List_Changed,
  // Server announces resource content updated
  Notifications_Resources_Updated,
  // Server announces prompt list changed
  Notifications_Prompts_List_Changed,
  // Server acknowledges a subscription
  Notifications_Subscriptions_Acknowledged,
  // Progress reporting for long-running operations
  Notifications_Progress,
  // Cancel a previously issued request
  Notifications_Cancelled,
  // Log message from a server or client
  Notifications_Message,
}

method_name :: proc(m: Method) -> string {
  switch m {
  case .Server_Discover:
    return "server/discover"
  case .Tools_List:
    return "tools/list"
  case .Tools_Call:
    return "tools/call"
  case .Resources_List:
    return "resources/list"
  case .Resources_Templates_List:
    return "resources/templates/list"
  case .Resources_Read:
    return "resources/read"
  case .Subscriptions_Listen:
    return "subscriptions/listen"
  case .Prompts_List:
    return "prompts/list"
  case .Prompts_Get:
    return "prompts/get"
  case .Completion_Complete:
    return "completion/complete"
  case .Elicitation_Create:
    return "elicitation/create"
  case .Notifications_Tools_List_Changed:
    return "notifications/tools/list_changed"
  case .Notifications_Resources_List_Changed:
    return "notifications/resources/list_changed"
  case .Notifications_Resources_Updated:
    return "notifications/resources/updated"
  case .Notifications_Prompts_List_Changed:
    return "notifications/prompts/list_changed"
  case .Notifications_Subscriptions_Acknowledged:
    return "notifications/subscriptions/acknowledged"
  case .Notifications_Progress:
    return "notifications/progress"
  case .Notifications_Cancelled:
    return "notifications/cancelled"
  case .Notifications_Message:
    return "notifications/message"
  }
  return ""
}

