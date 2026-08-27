# Path to the example MCP server package
hello := "examples/mcp-server/hello"
# Release binary the MCP client / inspector points at
bin := hello / "hello"
# Sanitizer binary used only by `check` (lives in an ignored tmp dir)
check_bin := hello / "tmp" / "hello_check"

# Show available recipes
default:
	@just --list

# Build a plain release binary of the hello MCP server
build:
	odin build {{hello}} -out:{{bin}}

# Build with AddressSanitizer + exercise every method to catch memory bugs
check:
	#!/usr/bin/env bash
	set -euo pipefail
	mkdir -p "$(dirname {{check_bin}})"
	odin build {{hello}} -debug -sanitize:address -out:{{check_bin}}
	export ASAN_OPTIONS=detect_stack_use_after_return=1
	M='"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientInfo":{"name":"check","version":"1.0.0"},"io.modelcontextprotocol/clientCapabilities":{"elicitation":{}}}'
	declare -a REQS=(
	  "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"server/discover\",\"params\":{$M}}"
	  "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/list\",\"params\":{$M}}"
	  "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"hello_tool\",\"arguments\":{\"name\":\"ada\",\"age\":30},$M}}"
	  "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"resources/list\",\"params\":{$M}}"
	  "{\"jsonrpc\":\"2.0\",\"id\":5,\"method\":\"resources/templates/list\",\"params\":{$M}}"
	  "{\"jsonrpc\":\"2.0\",\"id\":6,\"method\":\"resources/read\",\"params\":{\"uri\":\"file://main.rs\",$M}}"
	  "{\"jsonrpc\":\"2.0\",\"id\":7,\"method\":\"prompts/list\",\"params\":{$M}}"
	  "{\"jsonrpc\":\"2.0\",\"id\":8,\"method\":\"prompts/get\",\"params\":{\"name\":\"hello_prompt\",\"arguments\":{\"name\":\"world\"},$M}}"
	)
	fail=0
	for r in "${REQS[@]}"; do
	  method=$(printf '%s' "$r" | sed -E 's/.*"method":"([^"]+)".*/\1/')
	  out=$(printf '%s\n' "$r" | {{check_bin}} 2>&1 || true)
	  if printf '%s' "$out" | grep -q 'AddressSanitizer'; then
	    echo "FAIL [asan]    $method"
	    printf '%s\n' "$out" | grep -A3 'AddressSanitizer' | head -4
	    fail=1
	  elif ! printf '%s' "$out" | grep -q '"result":'; then
	    echo "FAIL [no-resp] $method"
	    fail=1
	  else
	    echo "ok             $method"
	  fi
	done
	if [ "$fail" -ne 0 ]; then echo "check: FAILED"; exit 1; fi
	echo "check: all methods clean under ASan"

# Build (release) and run the hello MCP server on stdio
run: build
	./{{bin}}

# Check, build (release), then run the hello MCP server on stdio
run-dev: check build
	./{{bin}}

# Launch the MCP Inspector against the hello server, pinned to the modern
# protocol era (2026-07-28) this SDK speaks. Default era is "legacy", which
# sends `initialize` and this server rejects; "modern" sends `server/discover`.
run-inspector: build
	#!/usr/bin/env bash
	set -euo pipefail
	cfg="{{justfile_directory() / hello}}/tmp/inspector.json"
	mkdir -p "$(dirname "$cfg")"
	cat > "$cfg" <<JSON
	{ "mcpServers": { "hello": { "type": "stdio", "command": "{{justfile_directory() / bin}}", "protocolEra": "modern" } } }
	JSON
	npx @modelcontextprotocol/inspector@latest --config "$cfg" --server hello

# Remove build artifacts
clean:
	rm -f {{bin}} {{check_bin}}
