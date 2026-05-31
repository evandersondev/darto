import 'package:darto/darto.dart';
import 'package:darto_ws/darto_ws.dart';

void main() async {
  final app = Darto();
  // One hub per app — tracks connections + rooms. Installing its middleware
  // lets the upgrade factories below reach it (ws.join / ws.to / …).
  final hub = WsHub();
  app.use(hub.middleware());

  // Simple echo — same port as HTTP (3000), no separate server needed.
  app.get(
      '/ws',
      [],
      upgradeWebSocket((c) => WSHandler(
            onOpen: (ws) {
              print('[ws] ${ws.id} connected');
              ws.send('connected');
            },
            onMessage: (event, ws) {
              print('[ws] received: ${event.text}');
              ws.send('echo: ${event.text}');
            },
            onClose: (ws) => print('[ws] ${ws.id} disconnected'),
            onError: (err, ws) => print('[ws] error: $err'),
          )));

  // Room chat — every message is broadcast to the whole room (real fanout,
  // not just an echo to the sender). `.except(ws)` skips the author.
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
        // ws.leave(room) happens automatically on close.
        ws.to(room).send('${ws.id} left');
      },
    );
  }));

  // JSON messages example.
  app.get(
      '/ws/json',
      [],
      upgradeWebSocket((c) => WSHandler(
            onMessage: (event, ws) {
              final payload = event.json; // Map<String, dynamic>
              ws.sendJson({'echo': payload});
            },
          )));

  // Server-initiated broadcast — push to a room from a plain HTTP route.
  app.post('/announce/:room', [], (Context c) async {
    final body = await c.req.json();
    hub.to(c.req.param('room')!).sendJson({'announce': body['text']});
    return c.noContent();
  });

  app.get(
      '/',
      [],
      (Context c) => c.ok({
            'connections': hub.connections,
            'rooms': hub.rooms.toList(),
            'endpoints': [
              'WS   /ws            — echo server',
              'WS   /chat/:room    — room chat with broadcast',
              'WS   /ws/json       — JSON round-trip',
              'POST /announce/:room — broadcast into a room over HTTP',
            ],
          }));

  // Single server, single port — HTTP and WS coexist.
  await app.listen(3000, () => print('Server on http://localhost:3000'));
}
