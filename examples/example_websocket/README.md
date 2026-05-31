# example_websocket

WebSocket with [`darto_ws`](../../darto_ws/) — same port as HTTP, with rooms and broadcast.

## What it shows
- `upgradeWebSocket()` on a normal route — HTTP and WS share port 3000.
- A **room chat** using `WsHub`: `ws.join(room)` + `ws.to(room).except(ws)` for real fanout (not just an echo).
- A server-initiated broadcast into a room from a plain HTTP `POST`.

## Endpoints
- `WS   /ws` — echo
- `WS   /chat/:room` — room chat (broadcast to everyone in the room)
- `WS   /ws/json` — JSON round-trip
- `POST /announce/:room` — broadcast into a room over HTTP

## Run
```bash
dart run bin/main.dart
```
Open two WS clients on `ws://localhost:3000/chat/lobby` and send a message from
one — the other receives it. Or push from HTTP:
```bash
curl -X POST localhost:3000/announce/lobby \
  -H 'Content-Type: application/json' -d '{"text":"hello room"}'
```

## Multi-instance
Behind a load balancer, attach the Redis adapter so broadcasts cross instances:

```dart
await hub.attachAdapter(await RedisWsAdapter.connect(host: 'localhost'));
```
