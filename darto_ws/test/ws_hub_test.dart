import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:darto/darto.dart';
import 'package:darto_ws/darto_ws.dart';
import 'package:test/test.dart';

/// Boots a Darto app on an ephemeral port and returns the bound port + the
/// hub.  Each test sets up its own routes so we exercise the real
/// upgrade/dispatch pipeline.
Future<({Darto app, WsHub hub, int port})> _bootApp(
  void Function(Darto app, WsHub hub) routes,
) async {
  final hub = WsHub();
  final app = Darto()..use(hub.middleware());
  routes(app, hub);

  final ready = Completer<void>();
  unawaited(app.serve(port: 0, shutdownSignals: false, onListen: ready.complete));
  await ready.future;
  return (app: app, hub: hub, port: app.port!);
}

/// Opens a WebSocket against `ws://127.0.0.1:port$path`.
Future<WebSocket> _connect(int port, String path) =>
    WebSocket.connect('ws://127.0.0.1:$port$path');

/// Drains the next [n] messages from [ws] within [timeout], collecting them
/// into a list.  Useful for assertions like "expect three sockets to receive
/// exactly this message".
Future<List<dynamic>> _drain(WebSocket ws, int n,
    {Duration timeout = const Duration(seconds: 2)}) async {
  final got = <dynamic>[];
  final c = Completer<List<dynamic>>();
  late StreamSubscription sub;
  sub = ws.listen((m) {
    got.add(m);
    if (got.length >= n) {
      sub.cancel();
      if (!c.isCompleted) c.complete(got);
    }
  }, onDone: () {
    if (!c.isCompleted) c.complete(got);
  });
  return c.future.timeout(timeout, onTimeout: () {
    sub.cancel();
    return got;
  });
}

void main() {
  group('WsHub — rooms and broadcast', () {
    test('two clients in the same room exchange messages', () async {
      final boot = await _bootApp((app, hub) {
        app.get('/chat/:room', [], upgradeWebSocket((c) {
          final room = c.req.param('room')!;
          return WSHandler(
            onOpen: (ws) => ws.join(room),
            onMessage: (ev, ws) => ws.to(room).sendJson({'from': ws.id, 'text': ev.text}),
          );
        }));
      });
      addTearDown(() async => boot.app.stop());

      final a = await _connect(boot.port, '/chat/lobby');
      final b = await _connect(boot.port, '/chat/lobby');
      // Give the server a moment to register both joins.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      a.add('hi from a');

      // Both sockets should receive a's message because `to(room)` fans out
      // to every member (including the sender — opt out with `.except(ws)`).
      final aReceived = await _drain(a, 1);
      final bReceived = await _drain(b, 1);

      expect(aReceived, hasLength(1));
      expect(bReceived, hasLength(1));
      expect(jsonDecode(aReceived.first as String)['text'], 'hi from a');
      expect(jsonDecode(bReceived.first as String)['text'], 'hi from a');

      await a.close();
      await b.close();
    });

    test('except(self) excludes the sender from a room broadcast', () async {
      final boot = await _bootApp((app, hub) {
        app.get('/chat/:room', [], upgradeWebSocket((c) {
          final room = c.req.param('room')!;
          return WSHandler(
            onOpen: (ws) => ws.join(room),
            onMessage: (ev, ws) =>
                ws.to(room).except(ws).send(ev.text),
          );
        }));
      });
      addTearDown(() async => boot.app.stop());

      final a = await _connect(boot.port, '/chat/r');
      final b = await _connect(boot.port, '/chat/r');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      a.add('echo me');

      final aBuf = await _drain(a, 1, timeout: const Duration(milliseconds: 300));
      final bBuf = await _drain(b, 1);

      expect(aBuf, isEmpty, reason: 'sender must be excluded');
      expect(bBuf, equals(['echo me']));

      await a.close();
      await b.close();
    });

    test('a socket in room A does not receive a message sent to room B',
        () async {
      final boot = await _bootApp((app, hub) {
        app.get('/chat/:room', [], upgradeWebSocket((c) {
          final room = c.req.param('room')!;
          return WSHandler(
            onOpen: (ws) => ws.join(room),
            onMessage: (ev, ws) => ws.to(room).send(ev.text),
          );
        }));
      });
      addTearDown(() async => boot.app.stop());

      final aRoom1 = await _connect(boot.port, '/chat/room1');
      final bRoom2 = await _connect(boot.port, '/chat/room2');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      aRoom1.add('only for room1');

      final got1 = await _drain(aRoom1, 1);
      final got2 = await _drain(bRoom2, 1, timeout: const Duration(milliseconds: 300));

      expect(got1, equals(['only for room1']));
      expect(got2, isEmpty);

      await aRoom1.close();
      await bRoom2.close();
    });

    test('hub.broadcast() reaches every connection', () async {
      final boot = await _bootApp((app, hub) {
        app.get('/ws', [], upgradeWebSocket((c)=> WSHandler()));
        app.post('/announce', [], (c) async {
          hub.broadcast().send('shutdown');
          return c.noContent();
        });
      });
      addTearDown(() async => boot.app.stop());

      final a = await _connect(boot.port, '/ws');
      final b = await _connect(boot.port, '/ws');
      final cConn = await _connect(boot.port, '/ws');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Fire the announcement over HTTP.
      final http = HttpClient();
      final req = await http.postUrl(Uri.parse('http://127.0.0.1:${boot.port}/announce'));
      await req.close();
      http.close(force: true);

      expect(await _drain(a, 1), equals(['shutdown']));
      expect(await _drain(b, 1), equals(['shutdown']));
      expect(await _drain(cConn, 1), equals(['shutdown']));

      await a.close();
      await b.close();
      await cConn.close();
    });

    test('hub.connections / roomSize / rooms track membership', () async {
      final boot = await _bootApp((app, hub) {
        app.get('/chat/:room', [], upgradeWebSocket((c) {
          final room = c.req.param('room')!;
          return WSHandler(onOpen: (ws) => ws.join(room));
        }));
      });
      addTearDown(() async => boot.app.stop());

      final a = await _connect(boot.port, '/chat/lobby');
      final b = await _connect(boot.port, '/chat/lobby');
      final cConn = await _connect(boot.port, '/chat/games');
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(boot.hub.connections, 3);
      expect(boot.hub.roomSize('lobby'), 2);
      expect(boot.hub.roomSize('games'), 1);
      expect(boot.hub.rooms.toSet(), {'lobby', 'games'});

      await a.close();
      await b.close();
      // Wait for the server to observe the close.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(boot.hub.connections, 1);
      expect(boot.hub.roomSize('lobby'), 0);

      await cConn.close();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(boot.hub.connections, 0);
      expect(boot.hub.rooms, isEmpty);
    });

    test('ws.leave() drops the socket from a single room', () async {
      final boot = await _bootApp((app, hub) {
        app.get('/chat/:room', [], upgradeWebSocket((c) {
          final room = c.req.param('room')!;
          return WSHandler(
            onOpen: (ws) => ws.join(room),
            onMessage: (ev, ws) {
              if (ev.text == 'leave') {
                ws.leave(room);
              } else {
                ws.to(room).send(ev.text);
              }
            },
          );
        }));
      });
      addTearDown(() async => boot.app.stop());

      final a = await _connect(boot.port, '/chat/r');
      final b = await _connect(boot.port, '/chat/r');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      a.add('leave');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      b.add('still here?');

      final got = await _drain(a, 1, timeout: const Duration(milliseconds: 300));
      expect(got, isEmpty, reason: 'a left the room — must not receive');

      await a.close();
      await b.close();
    });

    test('ws.join/to/leave throw when no hub is installed', () async {
      // Boot WITHOUT a hub middleware to assert the helpful error message.
      final app = Darto();
      app.get('/ws', [], upgradeWebSocket((c)=> WSHandler(
            onOpen: (ws) {
              try {
                ws.join('any');
              } on StateError catch (e) {
                ws.send(e.message);
              }
            },
          )));
      final ready = Completer<void>();
      unawaited(app.serve(port: 0, shutdownSignals: false, onListen: ready.complete));
      await ready.future;
      addTearDown(() async => app.stop());

      final ws = await _connect(app.port!, '/ws');
      final got = await _drain(ws, 1);
      expect(got, hasLength(1));
      expect(got.first, contains('hub.middleware()'));
      await ws.close();
    });
  });
}
