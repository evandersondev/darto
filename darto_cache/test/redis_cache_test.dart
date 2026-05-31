@Tags(['redis'])
library;

import 'dart:io';
import 'dart:math';

import 'package:darto_cache/darto_cache.dart';
import 'package:redis/redis.dart';
import 'package:test/test.dart';

/// Boots a disposable Redis container on a random host port, returns the
/// container id and the bound port.  Tests connect via `localhost:<port>`.
Future<({String id, int port})> _startRedis() async {
  // Pick a free ephemeral port.  We bind to `0` and read back what the OS
  // chose so two parallel suites never collide on the same port.
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

  // Wait for Redis to answer PING — TCP-open isn't enough on Docker because
  // the port-forward listens before redis-server is ready.
  for (var i = 0; i < 50; i++) {
    try {
      final conn = RedisConnection();
      final cmd = await conn.connect('127.0.0.1', port);
      final pong = await cmd.send_object(['PING']);
      await conn.close();
      if (pong == 'PONG') return (id: id, port: port);
    } catch (_) {
      // fallthrough — retry
    }
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
  late RedisCache cache;

  setUpAll(() async {
    final r = await _startRedis();
    _containerId = r.id;
    _port = r.port;
  });

  tearDownAll(() async {
    await _stopRedis(_containerId);
  });

  setUp(() async {
    // A fresh prefix per test isolates them on the same Redis instance.
    final prefix = 'test_${Random().nextInt(1 << 32)}:';
    cache = await RedisCache.connect(port: _port, prefix: prefix);
  });

  tearDown(() async {
    await cache.clear();
    await cache.close();
  });

  group('RedisCache', () {
    test('get returns null for an absent key', () async {
      expect(await cache.get('missing'), isNull);
    });

    test('set then get round-trips a Map', () async {
      await cache.set('user', {'id': 1, 'tags': ['a', 'b']});
      expect(
        await cache.get<Map<String, dynamic>>('user'),
        {'id': 1, 'tags': ['a', 'b']},
      );
    });

    test('set then get round-trips primitives', () async {
      await cache.set('n', 42);
      await cache.set('f', 3.14);
      await cache.set('s', 'hello');
      await cache.set('b', true);
      expect(await cache.get<int>('n'), 42);
      expect(await cache.get<double>('f'), 3.14);
      expect(await cache.get<String>('s'), 'hello');
      expect(await cache.get<bool>('b'), true);
    });

    test('delete returns true once and false on the second call', () async {
      await cache.set('k', 1);
      expect(await cache.delete('k'), true);
      expect(await cache.delete('k'), false);
    });

    test('has reflects presence', () async {
      await cache.set('k', 1);
      expect(await cache.has('k'), true);
      await cache.delete('k');
      expect(await cache.has('k'), false);
    });

    test('values past their TTL read back as null', () async {
      await cache.set('k', 'v', ttl: const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(await cache.get('k'), isNull);
    });

    test('clear only drops keys under the prefix', () async {
      // Drop a key under a *different* prefix and ensure clear() leaves it alone.
      final other = await RedisCache.connect(port: _port, prefix: 'other:');
      await other.set('keep', 1);
      await cache.set('a', 1);
      await cache.set('b', 2);

      await cache.clear();

      expect(await cache.get('a'), isNull);
      expect(await cache.get('b'), isNull);
      expect(await other.get<int>('keep'), 1);
      await other.delete('keep');
      await other.close();
    });

    test('remember calls the builder on miss and caches the result', () async {
      var built = 0;
      Future<int> build() async {
        built++;
        return 99;
      }

      expect(await cache.remember<int>('n', builder: build), 99);
      expect(await cache.remember<int>('n', builder: build), 99);
      expect(built, 1);
    });

    test('two clients share state via the same Redis', () async {
      final other = await RedisCache.connect(port: _port, prefix: cache.prefix);
      try {
        await cache.set('shared', 'yes');
        expect(await other.get<String>('shared'), 'yes');
      } finally {
        await other.close();
      }
    });
  });
}
