package server

import transport_layer "../transport"
import "core:fmt"
import "core:mem/virtual"

Server_Transport :: enum {
  stdio,
}

Server :: struct {}

run :: proc(server: ^Server, srv_transport: Server_Transport, allocator := context.allocator) {
  transport: ^transport_layer.Transport
  switch srv_transport {
  case .stdio:
    stdio := transport_layer.stdio_create(allocator)
    transport = &stdio.transport
  case:
    fmt.eprintfln("transport not implemented: %v", srv_transport)
    return
  }
  defer transport.close(transport)

  // use arena to allocate memory for the calls in the loop
  arena: virtual.Arena
  if err := virtual.arena_init_growing(&arena); err != nil {
    fmt.eprintfln("could not init arena: %v", err)
    return
  }
  defer virtual.arena_destroy(&arena)
  arena_allocator := virtual.arena_allocator(&arena)

  fmt.eprintln("Server running...")

  for {
    defer virtual.arena_free_all(&arena)
    context.allocator = arena_allocator

    bytes, err := transport.read(transport)
    if err != nil do break

    fmt.eprintfln("Bytes: %s", bytes)
  }
}

