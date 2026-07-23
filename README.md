# MCP Protocol

## Participants in the MCP architecture

- MCP Host: for example Visual Studio Code.
- MCP Client: a component that maintains a connection to an MCP server and obtains its context so the Host can use.
- MCP Server: the program that servers the context data.

## Layers

- Data layer: defines the JSON-RPC (2.0) based protocol for client-server communication.
- Transport layer: defines how that data will be transported between client and server (STDIO, HTTP)

## MCP Server

An MCP server is the program that servers context data.

- A "local" MCP server typically uses STDIO
- A "remote" MCP server typically uses Streamable HTTP transport.


## Lifecycle

MCP is a stateful protocol that requires lifecycle management. Its purpose is to negotiate the capabilities that both client and server support.

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
  - `resources/subscribe`: monitor resource changes. Returns a subscription confirmation.

- `Prompts`: reusable templates that help structure interactions with language models (system prompts). They are user-controlled, therefore require explicit invocation.
  
  Prompts protocol operations:

  - `prompts/list`: discover available prompts. Returns an array of prompt descriptors
  - `prompts/get`: retrieve prompt details. Returns full prompt definition with arguments

Each primitive type has associated methods for:

- discovery (`*/list`)
- retrieval (`*/get`)
- execution (`tools/call`)

MCP clients use the `*/list` to discover available primitives. Example `tools/list`. This allows the list to be dynamic.

### Client primitives

There are also some primitives that CLIENTS can expose:

- `sampling`: allows servers to request language model completions from the client's AI application. `sampling/createMessage`
- `elicitation`: allows servers to requests additional information from the user, like ask for confirmation of an action. `elicitation/create`
- `logging`: allows servers to send log messages to clients for debugging and monitoring purposes

## Notifications

The protocol supports real-time notification by using the JSON-RPC 2.0 notification messages without expecting a response. This can be useful when servers want to inform clients that something changed.

## Debugging

Go [here](https://modelcontextprotocol.io/docs/tools/inspector).

For the weather MCP server, do:
```sh
just debug-weather
```
