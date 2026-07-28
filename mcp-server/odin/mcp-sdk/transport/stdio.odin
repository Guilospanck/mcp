package transport

import "core:mem"
import "core:os"

NEWLINE_CHAR :: '\n'
CARRIAGE_RETURN_CHAT :: '\r'

Stdio_Error :: enum {
  None = 0,
  Closed,
  Write_Failed,
}

Stdio :: struct {
  transport: Transport,
  buf:       [dynamic]byte,
  allocator: mem.Allocator,
}

stdio_create :: proc(allocator := context.allocator) -> ^Stdio {
  // create our rawptr
  s := new(Stdio, allocator)

  s.allocator = allocator
  s.buf = make([dynamic]byte, allocator)

  s.transport = Transport {
    read  = stdio_read,
    write = stdio_write,
    close = stdio_close,
    data  = s,
  }

  return s
}

stdio_read :: proc(t: ^Transport) -> ([]byte, Transport_Error) {
  // tells us that t.data is a rawptr to a Stdio struct
  s := (^Stdio)(t.data)
  clear(&s.buf)

  // Each character is one byte
  c: [1]byte

  for {
    // MCP servers reads from the stdin
    lines_read, err := os.read(os.stdin, c[:])

    // if error or no lines read
    if err != nil || lines_read == 0 {
      // if this happens, we got a partial line (did not hit the '\n'),
      // but we still yield it
      if len(s.buf) > 0 do break

      return nil, .Closed
    }

    // we got to the end of our message
    if c[0] == NEWLINE_CHAR do break
    append(&s.buf, c[0])
  }

  // Remove a carriage return at the end of the line, if any
  if len(s.buf) > 0 && s.buf[len(s.buf) - 1] == CARRIAGE_RETURN_CHAT do pop(&s.buf)

  // This was an empty line. wait for real content
  if len(s.buf) == 0 do return stdio_read(t)

  return s.buf[:], nil
}

stdio_write :: proc(t: ^Transport, data: []byte) -> Transport_Error {

  // prevent a big data being only mid-written to the pipe
  written := 0

  for written < len(data) {
    lines_written, err := os.write(os.stdout, data[written:])
    if err != nil || lines_written <= 0 do return .Write_Failed
    written += lines_written
  }

  // write the newline char so we say we're done
  if _, err := os.write(os.stdout, {NEWLINE_CHAR}); err != nil do return .Write_Failed

  return nil
}

stdio_close :: proc(t: ^Transport) {
  s := (^Stdio)(t.data)
  delete(s.buf)
  free(s, s.allocator)
}

