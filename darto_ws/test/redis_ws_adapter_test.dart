@Tags(['redis'])
library;

import 'dart:async';
import 'dart:io';

import 'package:darto/darto.dart';
import 'package:darto_ws/darto_ws.dart';
import 'package:redis/redis.dart';
import 'package:test/test.dart';

/// Boots a disposable Redis container on a random host port and returns the
/// container id + the bound port.
Future<({String id, int port})> _startRedis() async {
  final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = probe.port;
  await probe.close();

  final r = await Process.run('docker', [
    'run',
    '-d',
    '--rm',
    '-p', '$port:6379',
    'redis:latest',
  ]);
  if (r.exitCode != 0) fail('docker run failed: ${r.stderr}');
  final id = (r.stdout as String).trim();

  // PING the server before returning — the port-forward is up before Redis is.
  for (var i = 0; i < 50; i++) {
    try {
      final conn = RedisConnection();
      final cmd = await conn.connect('127.0.0.1', port);
      final pong = await cmd.send_object(['PING']);
      await conn.close();
      if (pong == 'PONG') return (id: id, port: port);
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  await Process.run('docker', ['rm', '-f', id]);
  fail('Redis on port $port did not become reachable within 5s');
}

Future<void> _stopRedis(String id) =>
    Process.run('docker', ['rm', '-f', id]).then((_) {});

/// Boots a Darto app on an ephemeral port with its own hub.  Returns the
/// pieces tests will tear down at the end.
Future<({Darto app, WsHub hub, int port})> _bootApp(int redisPort,
    void Function(Darto app, WsHub hub) routes) async {
  final hub = WsHub();
  await hub.attachAdapter(await RedisWsAdapter.connect(port: redisPort));
  final app = Darto()..use(hub.middleware());
  routes(app, hub);

  final ready = Completer<void>();
  unawaited(app.serve(port: 0, shutdownSignals: false, onListen: ready.complete));
  await ready.future;
  return (app: app, hub: hub, port: app.port!);
}

Future<WebSocket> _connect(int port, String path) =>
    WebSocket.connect('ws://127.0.0.1:$port$path');

Future<List<dynamic>> _drain(WebSocket ws, int n,
    {Duration timeout = const Duration(seconds: 3)}) async {
  final got = <dynamic>[];
  final c = Completer<List<dynamic>>();
  late StreamSubscription sub;
  sub = ws.listen((m) {
    got.add(m);
    if (got.length >= n) {
      sub.cancel();
      if (!c.isCompleted) c.complete(got);
    }
  });
  return c.future.timeout(timeout, onTimeout: () {
    sub.cancel();
    return got;
  });
}

void main() {
  late String _redisId;
  late int _redisPort;

  setUpAll(() async {
    final r = await _startRedis();
    _redisId = r.id;
    _redisPort = r.port;
  });

  tearDownAll(() async => _stopRedis(_redisId));

  group('RedisWsAdapter', () {
    test('broadcast on instance A reaches a socket connected to instance B',
        () async {
      // Two independent Darto apps + hubs sharing one Redis — simulates two
      // replicas of the same service behind a load balancer.
      final a = await _bootApp(_redisPort, (app, hub) {
        app.get('/chat/:room', [], upgradeWebSocket((c) {
          final room = c.req.param('room')!;
          return WSHandler(onOpen: (ws) => ws.join(room));
        }));
      });
      final b = await _bootApp(_redisPort, (app, hub) {
        app.get('/chat/:room', [], upgradeWebSocket((c) {
          final room = c.req.param('room')!;
          return WSHandler(onOpen: (ws) => ws.join(room));
        }));
      });
      addTearDown(() async {
        await a.app.stop();
        await b.app.stop();
        await a.hub.close();
        await b.hub.close();
      });

      // Client connects to instance B.
      final wsOnB = await _connect(b.port, '/chat/lobby');
      // Give pub/sub a moment to subscribe to the room channel.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Server-side broadcast on instance A — must reach the client on B.
      a.hub.to('lobby').send('cross-instance!');

      final got = await _drain(wsOnB, 1);
      expect(got, equals(['cross-instance!']));
      await wsOnB.close();
    });

    test('a hub does not receive its own broadcast twice', () async {
      // Single instance, single socket — assert exactly one delivery even
      // though the message also round-trips through Redis.
      final a = await _bootApp(_redisPort, (app, hub) {
        app.get('/chat/:room', [], upgradeWebSocket((c) {
          final room = c.req.param('room')!;
          return WSHandler(onOpen: (ws) => ws.join(room));
        }));
      });
      addTearDown(() async {
        await a.app.stop();
        await a.hub.close();
      });

      final ws = await _connect(a.port, '/chat/r');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      a.hub.to('r').send('only once');
      // Drain expecting 2; we should still only ever see 1 within the timeout.
      final got = await _drain(ws, 2, timeout: const Duration(milliseconds: 600));
      expect(got, equals(['only once']));
      await ws.close();
    });

    test('hub.broadcast() reaches sockets on every instance', () async {
      final a = await _bootApp(_redisPort, (app, hub) {
        app.get('/ws', [], upgradeWebSocket((c) => WSHandler()));
      });
      final b = await _bootApp(_redisPort, (app, hub) {
        app.get('/ws', [], upgradeWebSocket((c) => WSHandler()));
      });
      addTearDown(() async {
        await a.app.stop();
        await b.app.stop();
        await a.hub.close();
        await b.hub.close();
      });

      final ca = await _connect(a.port, '/ws');
      final cb = await _connect(b.port, '/ws');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Broadcast from instance A — must reach the socket on B (and the one
      // on A, since broadcast()'s target set is "every local socket" and
      // the adapter re-fanouts on the peer).
      a.hub.broadcast().send('everyone');

      expect(await _drain(ca, 1), equals(['everyone']));
      expect(await _drain(cb, 1), equals(['everyone']));

      await ca.close();
      await cb.close();
    });
  });
}
