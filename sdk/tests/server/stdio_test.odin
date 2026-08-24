package server_test

import transport "../../transport"
import "core:testing"

@(test)
should_initialize_stdio_struct_correctly :: proc(t: ^testing.T) {
  allocator := context.temp_allocator
  defer free_all(allocator)

  s := transport.stdio_create(allocator)

  testing.expect(t, s != nil, "stdio_create should return a non-nil pointer")
  testing.expect(t, s.allocator == allocator, "allocator should be stored correctly")
  testing.expect(t, len(s.buf) == 0, "buffer should be initially empty")
  testing.expect(t, s.transport.data == s, "transport.data should point back to the Stdio struct")
  testing.expect(t, s.transport.read != nil, "transport.read should be assigned")
  testing.expect(t, s.transport.write != nil, "transport.write should be assigned")
  testing.expect(t, s.transport.close != nil, "transport.close should be assigned")
}

@(test)
should_close_stdio_without_crashing :: proc(t: ^testing.T) {
  allocator := context.temp_allocator
  defer free_all(allocator)

  s := transport.stdio_create(allocator)
  transport.stdio_close(&s.transport)
}

@(test)
should_transport_read_function_is_stdio_read :: proc(t: ^testing.T) {
  allocator := context.temp_allocator
  defer free_all(allocator)

  s := transport.stdio_create(allocator)

  testing.expect(
    t,
    s.transport.read == transport.stdio_read,
    "transport.read should point to stdio_read",
  )
}

@(test)
should_transport_write_function_is_stdio_write :: proc(t: ^testing.T) {
  allocator := context.temp_allocator
  defer free_all(allocator)

  s := transport.stdio_create(allocator)

  testing.expect(
    t,
    s.transport.write == transport.stdio_write,
    "transport.write should point to stdio_write",
  )
}

