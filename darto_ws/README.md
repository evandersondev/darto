# darto_ws

WebSocket support for [Darto](https://github.com/evandersondev/darto) — route-integrated, same port, Hono-style.

WebSocket routes live alongside HTTP routes on the same server and port. Middleware runs before the upgrade, so auth, param extraction, and state set via `c.set()` are all available inside the callbacks.

---

## Install

```yaml
dependencies:
  darto: ^1.0.0
  darto_ws: ^1.0.0
```

---

## Quick start

```dart
import 'package:darto/darto.dart';
import 'package:darto_ws/darto_ws.dart';

void main() async {
  final app = Darto();

  app.get('/ws', [], upgradeWebSocket((c) => WSHandler(
    onOpen:    (ws) => ws.send('connected'),
    onMessage: (event, ws) => ws.send('echo: ${event.text}'),
    onClose:   () => print('client disconnected'),
  )));

  await app.listen(3000);
}
```

Connect from a browser:

```js
const ws = new WebSocket('ws://localhost:3000/ws');
ws.onmessage = (e) => console.log(e.data);
ws.send('hello');
```

---

## `upgradeWebSocket(factory)`

Returns a `Handler` that upgrades the HTTP request to a WebSocket.  
The `factory` receives the full `Context` — path params, headers, and any middleware state — **before** the upgrade happens.

Pass route-level middlewares in the second argument as usual:

```dart
// Auth middleware runs before the WebSocket upgrade
app.get('/ws', [bearerAuth(token: env.token)], upgradeWebSocket((c) => WSHandler(
  onOpen: (ws) => ws.send('authenticated'),
)));
```

---

## Path params and middleware state

```dart
app.get('/chat/:room', [jwt(secret: env.secret)], upgradeWebSocket((c) {
  final room   = c.req.param('room')!;          // path param
  final userId = c.get<String>('userId');        // set by auth middleware

  return WSHandler(
    onOpen:    (ws) => ws.send('$userId joined $room'),
    onMessage: (event, ws) => ws.send('[$room] ${event.text}'),
  );
}));
```

---

## `WSHandler`

All callbacks are optional.

| Callback | Signature | When called |
|---|---|---|
| `onOpen` | `(DartoWebSocket ws)` | Handshake complete |
| `onMessage` | `(WSEvent event, DartoWebSocket ws)` | Message received |
| `onClose` | `(DartoWebSocket ws)` | Connection closed (read `ws.id` / `ws.rooms` here) |
| `onError` | `(Object error, DartoWebSocket ws)` | Protocol error |

> **Breaking in 1.1.0:** `onClose` and `onError` now receive the closing
> socket.  Old callers like `onClose: () => …` become `onClose: (_) => …`.

---

## Rooms and broadcast — `WsHub`

A `WsHub` is the connection registry — track sockets, group them in rooms and
fan messages out from anywhere.  Install one per app via middleware so every
`upgradeWebSocket` factory picks it up automatically.

```dart
import 'package:darto/darto.dart';
import 'package:darto_ws/darto_ws.dart';

void main() async {
  final hub = WsHub();
  final app = Darto()..use(hub.middleware());

  app.get('/chat/:room', [], upgradeWebSocket((c) {
    final room = c.req.param('room')!;
    return WSHandler(
      onOpen: (ws) {
        ws.join(room);
        ws.to(room).except(ws).send('${ws.id} joined');
      },
      onMessage: (event, ws) =>
        ws.to(room).sendJson({'from': ws.id, 'text': event.text}),
      onClose: (ws) {
        // ws.leave(room) is automatic on close
      },
    );
  }));

  // Server-initiated broadcast — works from any HTTP route, cron, etc.
  app.post('/announce', [], (c) async {
    final body = await c.req.json();
    hub.to('lobby').sendJson(body);
    return c.noContent();
  });

  await app.listen(3000);
}
```

`ws.to(room).send(...)` includes the sender by default; chain `.except(ws)`
to skip them.  `hub.broadcast().send(...)` reaches every connected socket.

| Member | Description |
|---|---|
| `hub.middleware()` | Darto middleware — exposes the hub to factories via `wsHub(c)` |
| `hub.to(room) / hub.broadcast()` | Fluent fanout — chain `.except(ws)`, then `send / sendJson / sendBytes` |
| `hub.connections / roomSize / rooms` | Membership stats |
| `ws.id / ws.rooms` | Per-connection UUID + the rooms it is in |
| `ws.join(room) / ws.leave(room)` | Mutate room membership (auto-leaves all rooms on close) |
| `ws.to(room) / ws.broadcast()` | Shortcuts to the hub — same as `hub.to(...)` |

---

## Multi-instance fanout — `RedisWsAdapter`

When you run multiple replicas behind a load balancer, sockets connected to
one instance can't see broadcasts emitted by another.  The Redis adapter
solves it: each `to(room).send(...)` is published to a Redis pub/sub channel,
peers re-fanout to their local sockets, and an origin id suppresses
self-echo.

```dart
final hub = WsHub();
await hub.attachAdapter(await RedisWsAdapter.connect(
  host: 'localhost',
  port: 6379,
));

final app = Darto()..use(hub.middleware());
// … routes as above; broadcasts now cross instances.
```

Run the adapter tests with:

```sh
dart test --tags redis
```

(requires Docker — the suite boots a disposable `redis:latest` on a random
host port.)

---

## `DartoWebSocket`

| Method | Description |
|---|---|
| `send(String)` | Send a text frame to *this* client |
| `sendJson(Map)` | Encode as JSON and send to *this* client |
| `sendBytes(List<int>)` | Send a binary frame to *this* client |
| `close([code, reason])` | Close the connection |
| `closeCode` | Close code from the peer (`null` while open) |
| `id` | Unique per-connection UUID v4 |
| `rooms` | Rooms this socket is in (mutable set) |
| `join(room) / leave(room)` | Mutate room membership |
| `to(room) / broadcast()` | Hub fanout helpers (require `hub.middleware()`) |

---

## `WSEvent`

| Member | Type | Description |
|---|---|---|
| `data` | `dynamic` | Raw frame data (`String` or `List<int>`) |
| `text` | `String` | UTF-8 decoded text |
| `json` | `Map<String, dynamic>` | JSON-decoded object |

---

## JSON round-trip

```dart
app.get('/ws/json', [], upgradeWebSocket((c) => WSHandler(
  onMessage: (event, ws) {
    final payload = event.json;          // Map<String, dynamic>
    ws.sendJson({'echo': payload});
  },
)));
```

---

## See also

- [darto](https://github.com/evandersondev/darto) — core framework
- [examples/example_websocket](../examples/example_websocket/) — working example

<br/>

---

<br/>

### Support 💖

If you find Darto WS useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the package and make it even better!

<br/>
