# JSON-RPC (2.0)

## Batch

Batch can happen, therefore the client can send an array of request objects to the server.

In that case, the server should respond with an array of response objects:

- AFTER ALL OF THE BATCH REQUEST OBJECTS HAVE BEEN PROCESSED.
- A response object SHOULD exist for each request - except that there SHOULD NOT be any response object for otifications
- Concurrency/parallelism MAY be used by the server to process the requests
- The response objects MAY be returned in any order within the Array - the client SHOULD match the contexts based on the `id`
- if the batch rpc call is not valid JSON, then the server MUST respond with a single Response object
- the server MUST NOT return an empty array - in that case, don't return anything at all
