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
| `onClose` | `()` | Connection closed |
| `onError` | `(Object error)` | Protocol error |

---

## `DartoWebSocket`

| Method | Description |
|---|---|
| `send(String)` | Send a text frame |
| `sendJson(Map)` | Encode as JSON and send |
| `sendBytes(List<int>)` | Send a binary frame |
| `close([code, reason])` | Close the connection |
| `closeCode` | Close code from the peer (`null` while open) |

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
