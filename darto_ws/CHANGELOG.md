## 1.1.0

- **Rooms + broadcast (`WsHub`)** — connection registry that tracks sockets
  and rooms, with a fluent fanout API: `hub.to(room).except(ws).send(text)`
  / `sendJson(map)` / `sendBytes(bytes)` and `hub.broadcast()`.  Usable
  anywhere a `Context` is available (WS callbacks, HTTP routes, jobs).
- **`DartoWebSocket` ergonomics** — `ws.id` (UUID v4), `ws.rooms`,
  `ws.join(room)`, `ws.leave(room)`, `ws.to(room)` and `ws.broadcast()`.
  The socket auto-leaves every room on close.
- **`hub.middleware()`** — registers the hub on the request `Context` so
  `upgradeWebSocket` factories can pick it up automatically; read it from
  any handler via `wsHub(c)`.
- **`RedisWsAdapter`** — pub/sub backend for multi-instance fanout.  Each
  hub publishes to per-room Redis channels (and `darto_ws:all` for
  `broadcast()`); peers re-fanout to their local sockets while origin-id
  tagging suppresses self-echo.  Attach via `hub.attachAdapter(...)`.
- **Breaking:** `WSHandler.onClose` and `WSHandler.onError` now receive the
  closing `DartoWebSocket`.  Callers add an `_` or `ws` parameter
  (`onClose: (ws) => …`).  Required so callbacks can read `ws.id` /
  `ws.rooms` before the hub tears the socket down.

## 1.0.1

- Require `darto: ^1.1.0`.
- docs: add Support section to README.

## 1.0.0

- Initial stable release.
