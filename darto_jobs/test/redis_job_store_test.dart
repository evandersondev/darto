@Tags(['redis'])
library;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:darto_jobs/darto_jobs.dart';
import 'package:redis/redis.dart';
import 'package:test/test.dart';

Future<({String id, int port})> _startRedis() async {
  final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = probe.port;
  await probe.close();

  final r = await Process.run('docker', [
    'run', '-d', '--rm', '-p', '$port:6379', 'redis:latest',
  ]);
  if (r.exitCode != 0) fail('docker run failed: ${r.stderr}');
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

Future<void> _stopRedis(String id) =>
    Process.run('docker', ['rm', '-f', id]).then((_) {});

Future<void> _until(Future<bool> Function() check,
    {Duration timeout = const Duration(seconds: 5)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await check()) {
    if (DateTime.now().isAfter(deadline)) fail('condition not met within $timeout');
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
}

void main() {
  late String _id;
  late int _port;

  setUpAll(() async {
    final r = await _startRedis();
    _id = r.id;
    _port = r.port;
  });

  tearDownAll(() async => _stopRedis(_id));

  // Fresh prefix per test isolates state on the shared Redis.
  Future<RedisJobStore> store() => RedisJobStore.connect(
        port: _port,
        prefix: 'test_${Random().nextInt(1 << 32)}:',
      );

  group('RedisJobStore', () {
    test('enqueue → reserve → ack round-trip', () async {
      final s = await store();
      final queue = JobQueue(store: s);
      final got = <String>[];
      queue.handle('greet', (job) async => got.add(job.data['name'] as String));

      await queue.add('greet', {'name': 'Eva'});
      final worker = queue.work(pollInterval: const Duration(milliseconds: 30));

      await _until(() async => got.isNotEmpty);
      expect(got, ['Eva']);

      await worker.stop();
      await s.close();
    });

    test('survives restart — a durable job persists across stores', () async {
      final prefix = 'persist_${Random().nextInt(1 << 32)}:';
      // Producer connects, enqueues, disconnects.
      final producer = await RedisJobStore.connect(port: _port, prefix: prefix);
      await JobQueue(store: producer).add('work', {'v': 7});
      await producer.close();

      // A brand-new store + worker (simulating a separate process) picks it up.
      final consumer = await RedisJobStore.connect(port: _port, prefix: prefix);
      final queue = JobQueue(store: consumer);
      final got = <int>[];
      queue.handle('work', (job) async => got.add(job.data['v'] as int));
      final worker = queue.work(pollInterval: const Duration(milliseconds: 30));

      await _until(() async => got.isNotEmpty);
      expect(got, [7]);

      await worker.stop();
      await consumer.close();
    });

    test('retry then dead-letter after maxAttempts', () async {
      final s = await store();
      final queue = JobQueue(store: s);
      queue.handle('boom', (job) async => throw StateError('always'),
          maxAttempts: 2, backoff: (_) => const Duration(milliseconds: 30));

      await queue.add('boom', {});
      final worker = queue.work(pollInterval: const Duration(milliseconds: 20));

      await _until(() async => (await s.stats()).dead == 1);
      final dead = await s.deadLetter();
      expect(dead.single.attempts, 2);

      await worker.stop();
      await s.close();
    });

    test('sweep recovers a job whose worker "crashed" (expired lease)', () async {
      final s = await store();
      final queue = JobQueue(store: s);
      await queue.add('orphan', {});

      // Reserve with a short lease and never ack — simulates a crash mid-job.
      final reserved = await s.reserve(const Duration(milliseconds: 50));
      expect(reserved, isNotNull);
      expect((await s.stats()).active, 1);

      await Future<void>.delayed(const Duration(milliseconds: 120));
      final recovered = await s.sweep();
      expect(recovered, 1);

      final st = await s.stats();
      expect(st.active, 0);
      expect(st.ready, 1);

      await s.close();
    });

    test('two workers do not double-process the same job', () async {
      final prefix = 'compete_${Random().nextInt(1 << 32)}:';
      final s1 = await RedisJobStore.connect(port: _port, prefix: prefix);
      final s2 = await RedisJobStore.connect(port: _port, prefix: prefix);
      final q1 = JobQueue(store: s1);
      final q2 = JobQueue(store: s2);

      final processed = <int>[];
      q1.handle('once', (job) async => processed.add(job.data['i'] as int));
      q2.handle('once', (job) async => processed.add(job.data['i'] as int));

      for (var i = 0; i < 10; i++) {
        await q1.add('once', {'i': i});
      }
      final w1 = q1.work(concurrency: 2, pollInterval: const Duration(milliseconds: 20));
      final w2 = q2.work(concurrency: 2, pollInterval: const Duration(milliseconds: 20));

      await _until(() async => processed.length >= 10);
      // Each job id processed exactly once → no duplicates.
      expect(processed.toSet(), {for (var i = 0; i < 10; i++) i});
      expect(processed.length, 10);

      await w1.stop();
      await w2.stop();
      await s1.close();
      await s2.close();
    });
  });
}
