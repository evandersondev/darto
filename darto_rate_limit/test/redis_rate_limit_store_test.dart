@Tags(['redis'])
library;

import 'dart:io';
import 'dart:math';

import 'package:darto_rate_limit/darto_rate_limit.dart';
import 'package:redis/redis.dart';
import 'package:test/test.dart';

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
  if (r.exitCode != 0) {
    fail('docker run failed (${r.exitCode}): ${r.stderr}');
  }
  final id = (r.stdout as String).trim();

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

Future<void> _stopRedis(String id) async {
  await Process.run('docker', ['rm', '-f', id]);
}

void main() {
  late String _containerId;
  late int _port;
  late RedisRateLimitStore store;

  setUpAll(() async {
    final r = await _startRedis();
    _containerId = r.id;
    _port = r.port;
  });

  tearDownAll(() async {
    await _stopRedis(_containerId);
  });

  setUp(() async {
    final prefix = 'test_${Random().nextInt(1 << 32)}:';
    store = await RedisRateLimitStore.connect(port: _port, prefix: prefix);
  });

  tearDown(() async {
    await store.close();
  });

  group('RedisRateLimitStore', () {
    test('counts hits within a window and shares state across calls', () async {
      final w = const Duration(seconds: 5);
      final h1 = await store.hit('user:1', w);
      final h2 = await store.hit('user:1', w);
      final h3 = await store.hit('user:1', w);
      expect(h1.count, 1);
      expect(h2.count, 2);
      expect(h3.count, 3);
      // All three hits share the same resetAt (give a small tolerance)
      expect(
        h3.resetAt.difference(h1.resetAt).inMilliseconds.abs(),
        lessThan(50),
      );
    });

    test('different keys are tracked independently', () async {
      final w = const Duration(seconds: 5);
      await store.hit('a', w);
      await store.hit('a', w);
      final hb = await store.hit('b', w);
      expect(hb.count, 1);
    });

    test('resetAt is within the configured window', () async {
      final w = const Duration(seconds: 2);
      final hit = await store.hit('k', w);
      final delta = hit.resetAt.difference(DateTime.now()).inMilliseconds;
      // Should be close to 2000 ms — wide tolerance for slow CI.
      expect(delta, inInclusiveRange(1500, 2200));
    });

    test('window expiry resets the counter', () async {
      final w = const Duration(milliseconds: 300);
      await store.hit('k', w);
      await store.hit('k', w);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      final h3 = await store.hit('k', w);
      expect(h3.count, 1, reason: 'Counter must reset after window expires');
    });

    test('reset() clears the counter immediately', () async {
      final w = const Duration(seconds: 5);
      await store.hit('k', w);
      await store.hit('k', w);
      await store.reset('k');
      final h = await store.hit('k', w);
      expect(h.count, 1);
    });

    test('two stores sharing the same Redis + prefix agree on the count',
        () async {
      // Simulates two app instances behind a load balancer.
      final other = await RedisRateLimitStore.connect(
        port: _port,
        prefix: store.prefix,
      );
      try {
        final w = const Duration(seconds: 5);
        final a = await store.hit('shared', w);
        final b = await other.hit('shared', w);
        final c = await store.hit('shared', w);
        expect(a.count, 1);
        expect(b.count, 2);
        expect(c.count, 3);
      } finally {
        await other.close();
      }
    });
  });
}
