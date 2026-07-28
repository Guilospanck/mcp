/*

Storage. Hold the tables and the API that the SDK's users call at startup

Registry never reads a request.
*/
package server

/*
> The client SHOULD NOT send requests other than `pings` before the server has responded to the `initialize` request;

> The server SHOULD NOT send requests other than `pings` and `logging` before receiving the `initialized` notification.

*/
Lifecycle :: enum {
  Uninitialized,
  Initializing,
  Initialized,
}

Server :: struct {
  state: Lifecycle,
}

