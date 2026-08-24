# Hello MCP Server

An example MCP server using the mcp-odin sdk.

## How to start

```sh
odin build .
```

This will generate a `hello` binary.

You can either run it with `./hello` and start sending MCP requests via the terminal to it or you can use the MCP inspector:

```sh
npx @modelcontextprotocol/inspector@latest
```
Then open `http://127.0.0.1:6274` and point to the full path of the `hello` binary.
