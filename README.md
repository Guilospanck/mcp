# MCP protocol (2026-07-28)

## Participants in the MCP architecture

- MCP Host: for example Visual Studio Code.
- MCP Client: a component that maintains a connection to an MCP server and obtains its context so the Host can use.
- MCP Server: the program that servers the context data. A "local" MCP server typically uses STDIO; a "remote" MCP server typically uses Streamable HTTP transport.

A host application creates and manages multiple clients, with each client having a 1:1 relationship with a particular server.

## Statelessness

MCP is a *stateless* protocol, which means that every request carries all the information needed to process it (in the `_meta` field), so servers infer nothing from previous requests.

> ![INFO]
> The implication of this is that an open connection, such as the STDIO process, is not a conversation or session. For those things, a client MUST pass an explicit identifier on each request.

## Message Patterns

- `Request and Response`
- `Multi Round-Trip Requests (MRTR)`: when a server requires client input to complete a request;
- `Subscribe and Notify`

## Primitives

Defines what client and servers can offer each other.

### Server primitives

- `Tools`: executable functions that can be invoked to perform actions (file operations, API calls, database queries)
  
  Tools protocol operations:

  - `tools/list`: discover available tools. Returns an array of tool definition with schemas.
  - `tools/call`: execute a specific tool. Returns the tool execution result.

- `Resources`: data sources (read-only) that provide contextual information (file contents, database records, API records). Each resource has a unique URI and declares its MIME type for appropriate content handling. There are two discovery patterns:
  a) Direct resources: fixed URIs that point to a specific data. Example `calendar://events/2024` returns calendar availability for 2024;
  b) Resource templates: dynamic URIs with parameters for flexible queries. Example `travel://activities/{city}/{category}` returns activities by city and category; `travel://activities/barcelona/museums` returns all museums in Barcelona.
  Resource templates include metadata such as title, description and expected MIME type, so they are discoverable and self-documenting.

  Resources protocol operations:

  - `resources/list`: list available direct resources. Returns an array of resources descriptors.
  - `resources/templates/list`: discover resource templates. Returns an array of resources template definitions.
  - `resources/read`: retrieve resource contents. Returns a resource data with metadata.
  - `subscriptions/listen`: monitor resource changes. Returns a stream of update notifications. See [Subscriptions](#subscriptions).

- `Prompts`: reusable templates that help structure interactions with language models (system prompts). They are user-controlled, therefore require explicit invocation.
  
  Prompts protocol operations:

  - `prompts/list`: discover available prompts. Returns an array of prompt descriptors
  - `prompts/get`: retrieve prompt details. Returns full prompt definition with arguments

## Subscriptions

`subscriptions/listen` opens a long-lived notification stream from the server to the client.

Unlike one-off requests, the stream stays open and delivers notifications _until the client cancels it_.

1. Opening a stream [client -> server]

The `notifications` params is a filter to whatever the client wants to be notified about (See [Notification Filter](https://modelcontextprotocol.io/specification/2026-07-28/basic/patterns/subscriptions#notification-filter) for more - all fields are optional. Omitting a field means that you're not subscribing to that type).
The server MUST NOT send notification types the client has not explicitly requested.

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "subscriptions/listen",
  "params": {

    // Present in every request
    "_meta": {
      "io.modelcontextprotocol/protocolVersion": "2026-07-28",
      "io.modelcontextprotocol/clientInfo": {
        "name": "ExampleClient",
        "version": "1.0.0"
      },
      "io.modelcontextprotocol/clientCapabilities": {}
    },

    "notifications": {
      "toolsListChanged": true,
      "resourceSubscriptions": ["file:///project/config.json"]
    }
  }
}
```

2. Acknowledgment [server -> client]

The server MUST send `notifications/subscriptions/acknowledged` first and MUST NOT send any notification on the subscription before it.

Note that under the `_meta` object we must have `io.modelcontextprotocol/subscriptionId` with the subscription id.

Also note that `notifications` field reflects the subset that the server agreed to honor (therefore, it could happen that a client asked for notifications about a lot of things but the server only agreed on some of them , not all).

```json
{
  "jsonrpc": "2.0",
  "method": "notifications/subscriptions/acknowledged",
  "params": {
    "_meta": {
      "io.modelcontextprotocol/subscriptionId": 1
    },
    "notifications": {
      "toolsListChanged": true,
      "resourceSubscriptions": ["file:///project/config.json"]
    }
  }
}
```

3. Receiving notifications [server -> client]

The server sends `notifications/resources/updated` that carries under the `_meta` object the `io.modelcontextprotocol/subscriptionId` with the subscription id that identifies the `subscriptions/listen` request that opened the stream.

```json
{
  "jsonrpc": "2.0",
  "method": "notifications/resources/updated",
  "params": {
    "_meta": {
      "io.modelcontextprotocol/subscriptionId": 1
    },
    "uri": "file:///project/config.json"
  }
}
```

4. Cancellation

A subscription ends when:

- The underlying transport closes (HTTP timeout, TCP disconnect, stdio process exit);
- The *client* cancels it: close the SSE stream (HTTP) or send `notifications/cancelled` referencing the `subscriptions/listen` request ID (stdio). See [Cancellation](#cancellation);
- The *server* tears it down (e.g. during shutdown):

a) it SHOULD send the empty `subscriptions/listen` response to signal a graceful end, then close the stream. The graceful shutdown:

```json
// Graceful shutdown of a subscription
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "resultType": "complete",
    "_meta": {
      "io.modelcontextprotocol/subscriptionId": 1
    }
  }
}
```

b) it MUST send `notifications/cancelled` referencing a `subscriptions/listen` request ID

## Cancellation

You can use this to cancel in-progress requests.

```json
{
  "jsonrpc": "2.0",
  "method": "notifications/cancelled",
  "params": {
    "requestId": "123", // required
    "reason": "User requested cancellation" // optional
  }
}
```
Invalid cancellation notifications SHOULD be ignored:

- Unknown request IDS
- Already completed requests
- Malformed notifications

This maintains the "fire and forget" nature of notifications.

## Layers

- Data layer: defines the JSON-RPC (2.0) based protocol for client-server communication.
- Transport layer: defines how that data will be transported between client and server (stdio, Streamable HTTP)

## Data Layer

### Discovery

Every request carries the protocol version and the capabilities relevant to that request in its `_meta` field.

Servers MUST advertise their supported versions and capabilities through the mandatory `server/discover` request,
but note that CALLING `server/discover` is OPTIONAL: because every request carries the same `_meta` fields, a client is free to send any request directly and handle a version error (`UnsupportedProtocolVersionError`) if one comes back.

> [!NOTE]
> What this means is that every request coming from the Client will ALWAYS have the client's metadata.
> But responses coming from the Server won't. Server only shares his metadata when answering a `server/discover` request.

Discovery is a convenient way to fetch the server's identity, capabilities and supported versions in a single request.

```json
// Discover Request
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "server/discover",
  "params": {
    "_meta": {
      "io.modelcontextprotocol/protocolVersion": "2026-07-28",
      "io.modelcontextprotocol/clientInfo": {
        "name": "example-client",
        "version": "1.0.0"
      },
      "io.modelcontextprotocol/clientCapabilities": {
        "elicitation": {}
      }
    }
  }
}

// Discover Response (CACHEABLE)
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "resultType": "complete",
    "supportedVersions": ["2026-07-28"],
    "capabilities": {
      "tools": {
        "listChanged": true
      },
      "resources": {}
    },
    "_meta": {
      "io.modelcontextprotocol/serverInfo": {
        "name": "example-server",
        "version": "1.0.0"
      }
    },
    "ttlMs": 3600000,
    "cacheScope": "public"
  }
}
```

#### result and `_meta` fields

- (client) `io.modelcontextprotocol/protocolVersion`: which version the client is speaking on this request;
- (server) `supportedVersions`: the versions that the server accepts. If the server does not support the requested version, it rejects the request with an `UnsupportedProtocolVersionError`, listing the versions that he does support - and then the client can retry with a mutually supported version;
- (client) `io.modelcontextprotocol/clientCapabilities`: the client capabilities;
- (server) `capabilities`: the server capabilities;
- (client/server) `io.modelcontextprotocol/clientInfo` and `io.modelcontextprotocol/serverInfo`: identity exchange for debugging and compatibility purposes.

### Tool Discovery

Client can send a `tools/list` request.

```json
// Tools List Request
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/list",
  "params": {
    "_meta": {
      "io.modelcontextprotocol/protocolVersion": "2026-07-28",
      "io.modelcontextprotocol/clientInfo": {
        "name": "example-client",
        "version": "1.0.0"
      },
      "io.modelcontextprotocol/clientCapabilities": {
        "elicitation": {}
      }
    }
  }
}

// Tools List Response
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "resultType": "complete",
    "tools": [
      {
        "name": "calculator_arithmetic",
        "title": "Calculator",
        "description": "Perform mathematical calculations including basic arithmetic, trigonometric functions, and algebraic operations",
        "inputSchema": {
          "type": "object",
          "properties": {
            "expression": {
              "type": "string",
              "description": "Mathematical expression to evaluate (e.g., '2 + 3 * 4', 'sin(30)', 'sqrt(16)')"
            }
          },
          "required": ["expression"]
        }
      },
      {
        "name": "weather_current",
        "title": "Weather Information",
        "description": "Get current weather information for any location worldwide",
        "inputSchema": {
          "type": "object",
          "properties": {
            "location": {
              "type": "string",
              "description": "City name, address, or coordinates (latitude,longitude)"
            },
            "units": {
              "type": "string",
              "enum": ["metric", "imperial", "kelvin"],
              "description": "Temperature units to use in response",
              "default": "metric"
            }
          },
          "required": ["location"]
        }
      }
    ],
    "ttlMs": 300000,
    "cacheScope": "public"
  }
}
```

#### Tool Discovery Request

There are no required params other than the `_meta` that's present in every request.
It also accepts an optional `cursor` paramter for [pagination](https://modelcontextprotocol.io/specification/2026-07-28/server/utilities/pagination).

### Tool Execution (tools/call)

```json
// Tool Call Request
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "weather_current",
    "arguments": {
      "location": "San Francisco",
      "units": "imperial"
    },
    "_meta": {
      "io.modelcontextprotocol/protocolVersion": "2026-07-28",
      "io.modelcontextprotocol/clientInfo": {
        "name": "example-client",
        "version": "1.0.0"
      },
      "io.modelcontextprotocol/clientCapabilities": {
        "elicitation": {}
      }
    }
  }
}

// Tool Call Response
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": {
    "resultType": "complete",
    // It's an array, so the result can be a rich one.
    "content": [
      {
        "type": "text", // MCP supports different types
        "text": "Current weather in San Francisco: 68°F, partly cloudy with light winds from the west at 8 mph. Humidity: 65%"
      }
    ]
  }
}
```

### Caching

#### Cacheable results

Servers MUST include caching hints on results with `resultType: "complete"` returned by the following operations:

- `server/discover`
- `tools/list`
- `prompts/list`
- `resources/list`
- `resources/templates/list`
- `resources/read`

> [!NOTE]
> Interim results with `resultType: "input_required"` are not cacheable and carry no caching hints.

#### Cacheable Model

- Time-to-live (TTL), `ttlMs`: specifies how long in milliseconds the client MAY consider the result fresh;
- Cache Scope , `cacheScope`: the intended scope of the cached response, either `public` or `private`.

> [!NOTE]
> `ttlMs` is a freshness hint, not a guarantee.

###### Choosing a Cache Scope

- "public": it means that doesn't contain user-specific data. This is appropriate for a list of tools, prompts, and resource templates when they are identical to all users;
- "private": it means that it does contain user-specific data. This is appropriate for `resources/read` results, or for filtered list results that vary per user.

> [!NOTE]
> Be aware that a "public" cacheScope means that a result could be shared with other requests (even with different authentications).

##### Interaction with Pagination

- A server MAY return different `ttlMs` for each page
- A server MUST applyt the same `cacheScope` to all response pages.
























