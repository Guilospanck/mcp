# MCP (2026-07-28)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

MCP (Model Context Protocol) [version 2026-07-28](https://modelcontextprotocol.io/docs/2026-07-28/getting-started/intro) implementation in Odin.

> [!NOTE]  
> This repo is totally hand-crafted. No AI was used to write any code.

## Available functionalities

> [!NOTE]
> Still under development. As of this writing, only some simple functionalities for a MCP server are available in the SDK. None for a MCP client yet.

- [x] `server/discover` (Client -> Server)
- [x] `tools/list` (Client -> Server)
- [x] `tools/call` (Client -> Server)
- [x] `resources/list` (Client -> Server)
- [x] `resources/templates/list` (Client -> Server)
- [x] `resources/read` (Client -> Server)
- [x] `prompts/list` (Client -> Server)
- [x] `prompts/get` (Client -> Server) 
- [ ] `completion/complete` (Client -> Server) 
- [ ] `subscriptions/listen` (Client -> Server) 
- [ ] `notifications/cancelled` (Client -> Server; also Server -> Client on stdio)
- [ ] `notifications/tools/list_changed` (Server -> Client)
- [ ] `notifications/resources/list_changed` (Server -> Client)
- [ ] `notifications/resources/updated` (Server -> Client)
- [ ] `notifications/prompts/list_changed` (Server -> Client)  
- [ ] `notifications/subscriptions/acknowledged` (Server -> Client)
- [ ] `notifications/progress` (Server -> Client)
- [ ] `notifications/message` (Server -> Client)
- [ ] `elicitation/create` (Server -> Client)

Also notice that not everything that is not required in the methods above (like `nextCursor`, for example) are available. It's only the leanest of the leanest.

## How to use

There's an example implementation of a [hello MCP server](./examples/mcp-server/hello/). Check its README for info on how to spin it up.

## Docs

Check the [docs](./docs/mcp_2026-07-28.md) for a distillation of the protocol with what I wrote while going through their website documentation.

## License

[MIT](./LICENSE)

