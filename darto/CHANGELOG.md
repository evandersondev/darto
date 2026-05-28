## 1.2.0

- **Server hardening:**
  - `serve({port, host, securityContext, shutdownSignals, onListen})` — full
    control over host binding and **HTTPS/TLS** (`securityContext`).
  - `listenSecure(port, securityContext, [callback])` — HTTPS convenience.
  - **Graceful shutdown:** `stop({drainTimeout})` now stops accepting new
    connections and drains in-flight requests before force-closing; by default
    `serve`/`listen` trap `SIGINT`/`SIGTERM` and shut down gracefully.
  - `port` / `address` getters — useful for ephemeral binds (`serve(port: 0)`).
- **New middleware** `requestId()` (`package:darto/request_id.dart`) — assigns a
  UUID v4 per request (honors an incoming header), stored in context and echoed
  in the response. Read it with `requestIdOf(c)`.
- **New middleware** `etag()` (`package:darto/etag.dart`) — ETag for dynamic
  responses with automatic `304 Not Modified` on `If-None-Match`.
- **New middleware** `rateLimit()` (`package:darto/rate_limit.dart`) — caps
  requests per key within a window, in-memory and zero-dep by default
  (`MemoryRateLimitStore`), with a pluggable `RateLimitStore` interface for
  distributed backends. Emits `RateLimit-*` headers and `Retry-After`.
- **New helper** `health()` (`package:darto/health.dart`) — a liveness/readiness
  handler returning `200`/`503` from named checks (`/healthz`, `/readyz`).
- `Response.withHeader()` and `Response.bodyBytes()` helpers.
- **Router performance:** literal routes (no params, wildcards or regex
  metacharacters) are now matched with a direct string compare instead of a
  compiled `RegExp` — the common case on the hot dispatch path (~100× cheaper
  per match in a micro-benchmark). Dispatch also short-circuits on HTTP method
  before evaluating the matcher. Matching semantics are unchanged (params,
  optional/regex params, wildcards, mounts and strict mode all behave exactly
  as before).
- **Fix:** cookie helpers read the **request** `Cookie` header (not the
  response), parse values containing `=` (base64url), and emit multiple
  `Set-Cookie` headers via `headers.add`. This also fixes session reads.
- **Fix:** `sessionContext(c).get()` now returns `null` (instead of throwing a
  `TypeError`) when there is no active session.

## 1.1.0

- **BREAKING:** HonoJS-aligned request/response body API.
  - `c.body()` is now a **response** helper (sends the response body): accepts a
    `String` (→ `text/plain`), `List<int>` (→ `application/octet-stream`, with
    optional headers) or `null` (empty body).
  - Removed `c.body()` / `c.bodyRaw()` as request-body readers from `Context`.
  - Read the request body via `c.req`: `c.req.json()`, `c.req.text()` (new),
    `c.req.blob()`, `c.req.arrayBuffer()`, `c.req.parseBody()`, `c.req.formData()`.
  - Added `c.req.body` getter — the raw request body `Stream<List<int>>`
    (HonoJS-style). `c.req.rawStream` is kept as an alias.
  - Migration: replace `await c.body()` with `await c.req.json()` and
    `await c.bodyRaw()` with `await c.req.blob()`.

## 0.0.35

- Chore methods and performace

## 0.0.34

- Fix version darto_types in 0.0.2

## 0.0.33

- Update Darto Types from Response

## 0.0.32

- Add the res.write method to accept String or Uint8List

## 0.0.31

- Update basePath method and add example stop method

## 0.0.30

- Remove types and a new package darto_types

## 0.0.29

- Websocket fix sintaxe.

## 0.0.28

- Fix websocket to broadcastings and update sintaxe.

## 0.0.27

- Add support middleware for context routes.

## 0.0.26

- Ensure errorMiddleware receives Exception to prevent crash due to Error received.

## 0.0.25

- Private methods, add new methods to Response, Resquest, DartoBase, and Router.

## 0.0.24

- Add chained routes, param method, add support for next funcation a optional param like Exception.

## 0.0.23

- Add hooks, update logger and add new method to create routes.

## 0.0.22

- Remove dart mirrors to resolve compile error.

## 0.0.21

- Add more methods from response.

## 0.0.20

- Add context from request and remove header from response.

## 0.0.19

- Expose Middleware type.

## 0.0.18

- Update send method response.

## 0.0.17

- Update request body auto conversion.

## 0.0.16

- Fix path when router not have prefix.

## 0.0.15

- Add suport for template engine mustache.

## 0.0.14

- Fix implicit return.

## 0.0.13

- Add generic error handler and add more http methods.

## 0.0.12

- Add send email support.

## 0.0.11

- Add timeout global middleware and error global middleware.

## 0.0.10

- Add subroutes and web sockets.

## 0.0.9

- Update middlewares.

## 0.0.8

- Add middlewares to routes.

## 0.0.7

- Update serialization.

## 0.0.6

- Update serialization.

## 0.0.5

- Add render method.

## 0.0.4

- Add buy me a coffee link.

## 0.0.3

- Add serialization dynamic to json.

## 0.0.2

- Update range dart SDK.

## 0.0.1

- Create initial version.
