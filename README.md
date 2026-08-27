# MCP (2026-07-28)

MCP (Model Context Protocol) [version 2026-07-28](https://modelcontextprotocol.io/docs/2026-07-28/getting-started/intro) implementation in Odin.

> [!NOTE]  
> This repo is totally hand-crafted. No AI was used to write any code.

## Available functionalities

> [!NOTE]
> Still under development. As of this writing, only some simple functionalities for a MCP server are available in the SDK. None for a MCP client yet.

- [x] `server/discover`
- [x] `tools/list`
- [x] `tools/call`
- [x] `resources/list`
- [x] `resources/templates/list`
- [x] `resources/read`
- [x] `prompts/list`
- [x] `prompts/get`
- [ ] `subscriptions/listen`
- [ ] `completion/complete`
- [ ] `elicitation/create`
- [ ] `notifications/tools/list_changed`
- [ ] `notifications/resources/list_changed`
- [ ] `notifications/resources/updated`
- [ ] `notifications/prompts/list_changed`
- [ ] `notifications/subscriptions/acknowledged`
- [ ] `notifications/progress`
- [ ] `notifications/cancelled`
- [ ] `notifications/message`

Also notice that not everything that is not required in the methods above (like `nextCursor`, for example) are available. It's only the leanest of the leanest.

## How to use

There's an example implementation of a [hello MCP server](./examples/mcp-server/hello/). Check its README for info on how to spin it up.

## Docs

Check the [docs](./docs/mcp_2026-07-28.md) for a distillation of the protocol with what I wrote while going through their website documentation.

