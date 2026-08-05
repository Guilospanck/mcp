package server_test

import transport "../../transport"
import "core:mem"

Mock_Transport :: struct {
  transport: transport.Transport,
  inputs:    [][]byte, // canned requests, fed in order
  idx:       int,
  outputs:   [dynamic][]byte, // captured responses
  allocator: mem.Allocator,
}

mock_transport_create :: proc(
  inputs: [][]byte,
  allocator := context.allocator,
) -> ^Mock_Transport {
  m := new(Mock_Transport, allocator)
  m.inputs = inputs
  m.allocator = allocator
  m.outputs = make([dynamic][]byte, allocator)

  m.transport = transport.Transport {
    read  = mock_transport_read,
    write = mock_transport_write,
    close = mock_transport_close,
    data  = m,
  }
  return m
}

mock_transport_read :: proc(t: ^transport.Transport) -> ([]byte, transport.Transport_Error) {
  m := (^Mock_Transport)(t.data)
  if m.idx >= len(m.inputs) {
    return nil, .Closed // no more inputs -> loop ends
  }
  line := m.inputs[m.idx]
  m.idx += 1
  return line, nil
}

mock_transport_write :: proc(t: ^transport.Transport, data: []byte) -> transport.Transport_Error {
  m := (^Mock_Transport)(t.data)
  // copy — data may be arena memory freed after this iteration
  cp := make([]byte, len(data), m.allocator)
  copy(cp, data)
  append(&m.outputs, cp)
  return nil
}

mock_transport_close :: proc(t: ^transport.Transport) {
  m := (^Mock_Transport)(t.data)
  delete(m.outputs)
  free(m, m.allocator)
}

