import 'package:darto/darto.dart';
import 'package:darto_ws/darto_ws.dart';

void main() async {
  final app = Darto();

  // Simple echo — same port as HTTP (3000), no separate server needed.
  app.get('/ws', [], upgradeWebSocket((c) => WSHandler(
        onOpen: (ws) {
          print('[ws] client connected');
          ws.send('connected');
        },
        onMessage: (event, ws) {
          print('[ws] received: ${event.text}');
          ws.send('echo: ${event.text}');
        },
        onClose: () => print('[ws] client disconnected'),
        onError: (err) => print('[ws] error: $err'),
      )));

  // Chat room — path param available before upgrade.
  app.get('/chat/:room', [], upgradeWebSocket((c) {
    final room = c.req.param('room')!;
    return WSHandler(
      onOpen: (ws) => ws.send('Joined room "$room"'),
      onMessage: (event, ws) => ws.send('[$room] ${event.text}'),
      onClose: () => print('[ws] left room "$room"'),
    );
  }));

  // JSON messages example.
  app.get('/ws/json', [], upgradeWebSocket((c) => WSHandler(
        onMessage: (event, ws) {
          final payload = event.json; // Map<String, dynamic>
          ws.sendJson({'echo': payload});
        },
      )));

  app.get('/', [], (Context c) => c.ok({
        'endpoints': [
          'WS  /ws         — echo server',
          'WS  /chat/:room — room-scoped chat',
          'WS  /ws/json    — JSON round-trip',
        ]
      }));

  // Single server, single port — HTTP and WS coexist.
  await app.listen(3000, () => print('Server on http://localhost:3000'));
}
