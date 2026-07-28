package transport

Transport_Error :: union {
  Stdio_Error,
}

Transport :: struct {
  read:  proc(t: ^Transport) -> ([]byte, Transport_Error),
  write: proc(t: ^Transport, data: []byte) -> Transport_Error,
  close: proc(t: ^Transport),
  // this is what implementations will use to pig-back to themselves
  data:  rawptr,
}

