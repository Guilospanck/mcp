# Hello MCP Server

An example MCP server using the mcp-odin sdk.

## How to start

The [`.justfile`](../../../.justfile) at the repo root drives building, checking,
and running this server. Run any recipe with [`just`](https://github.com/casey/just)
from the repo root:

| Recipe               | What it does                                                                                     |
| -------------------- | ------------------------------------------------------------------------------------------------ |
| `just build`         | Build a plain release binary of the hello MCP server (`examples/mcp-server/hello/hello`).         |
| `just check`         | Build with AddressSanitizer and exercise every MCP method, so memory bugs (e.g. a stack-use-after-return from a dangling slice/compound literal) fail loudly instead of corrupting a response. |
| `just run`           | Build (release) and run the server on stdio.                                                      |
| `just run-dev`       | `check`, then build (release) and run the server on stdio.                                        |
| `just run-inspector` | Build, then launch the [MCP Inspector](https://github.com/modelcontextprotocol/inspector) against the server, pinned to the modern protocol era (`2026-07-28`) this SDK speaks. |
| `just clean`         | Remove build artifacts.                                                                           |

> **Protocol era:** the Inspector defaults to the *legacy* era, which sends
> `initialize` — a method this server rejects. `just run-inspector` pins the
> connection to the *modern* era (`server/discover` + `_meta` envelope), so it
> connects out of the box. If you launch the Inspector by hand, set
> **Protocol Era = Modern** for the server.
