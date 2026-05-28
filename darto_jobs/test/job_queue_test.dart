import 'dart:async';

import 'package:darto_jobs/darto_jobs.dart';
import 'package:test/test.dart';

/// Polls [check] until it returns true or [timeout] elapses.
Future<void> _until(bool Function() check,
    {Duration timeout = const Duration(seconds: 3)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!check()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  group('JobQueue + MemoryJobStore', () {
    test('processes an enqueued job', () async {
      final queue = JobQueue(store: MemoryJobStore());
      final got = <String>[];
      queue.handle('greet', (job) async => got.add(job.data['name'] as String));

      await queue.add('greet', {'name': 'Eva'});
      final worker = queue.work(pollInterval: const Duration(milliseconds: 20));

      await _until(() => got.isNotEmpty);
      expect(got, ['Eva']);

      await worker.stop();
      await queue.close();
    });

    test('runs jobs in registration-independent order with concurrency', () async {
      final queue = JobQueue(store: MemoryJobStore());
      final done = <int>[];
      queue.handle('n', (job) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        done.add(job.data['i'] as int);
      });

      for (var i = 0; i < 20; i++) {
        await queue.add('n', {'i': i});
      }
      final worker = queue.work(concurrency: 4, pollInterval: const Duration(milliseconds: 10));

      await _until(() => done.length == 20, timeout: const Duration(seconds: 5));
      expect(done.toSet(), {for (var i = 0; i < 20; i++) i});

      await worker.stop();
      await queue.close();
    });

    test('retries with backoff then succeeds', () async {
      final queue = JobQueue(store: MemoryJobStore());
      var tries = 0;
      queue.handle('flaky', (job) async {
        tries++;
        if (job.attempts < 3) throw StateError('boom #${job.attempts}');
      }, maxAttempts: 3, backoff: (_) => const Duration(milliseconds: 20));

      await queue.add('flaky', {});
      final worker = queue.work(pollInterval: const Duration(milliseconds: 10));

      await _until(() => tries >= 3, timeout: const Duration(seconds: 5));
      expect(tries, 3);
      // No failure should have been recorded — it eventually succeeded.
      expect((await queue.store.stats()).dead, 0);

      await worker.stop();
      await queue.close();
    });

    test('exhausts attempts → dead-letter + onFailed hook', () async {
      final queue = JobQueue(store: MemoryJobStore());
      Object? capturedError;
      Job? capturedJob;
      queue.onFailed((job, err, _) {
        capturedJob = job;
        capturedError = err;
      });
      queue.handle('always-fails', (job) async {
        throw StateError('nope');
      }, maxAttempts: 2, backoff: (_) => const Duration(milliseconds: 10));

      await queue.add('always-fails', {'x': 1});
      final worker = queue.work(pollInterval: const Duration(milliseconds: 10));

      await _until(() => capturedError != null, timeout: const Duration(seconds: 5));

      expect(capturedJob?.name, 'always-fails');
      expect(capturedError, isA<StateError>());
      final dead = await queue.store.deadLetter();
      expect(dead, hasLength(1));
      expect(dead.single.attempts, 2);

      await worker.stop();
      await queue.close();
    });

    test('delayed job does not run before its time', () async {
      final queue = JobQueue(store: MemoryJobStore());
      final got = <String>[];
      queue.handle('later', (job) async => got.add('ran'));

      await queue.add('later', {}, delay: const Duration(milliseconds: 400));
      final worker = queue.work(pollInterval: const Duration(milliseconds: 20));

      // Not yet.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(got, isEmpty);

      // Eventually.
      await _until(() => got.isNotEmpty, timeout: const Duration(seconds: 2));
      expect(got, ['ran']);

      await worker.stop();
      await queue.close();
    });

    test('a job with no registered handler is dead-lettered', () async {
      final queue = JobQueue(store: MemoryJobStore());
      Object? err;
      queue.onFailed((job, e, _) => err = e);

      await queue.add('unknown', {});
      final worker = queue.work(pollInterval: const Duration(milliseconds: 10));

      await _until(() => err != null, timeout: const Duration(seconds: 3));
      expect(err, isA<StateError>());
      expect((await queue.store.deadLetter()), hasLength(1));

      await worker.stop();
      await queue.close();
    });

    test('sweep recovers an expired lease', () async {
      final store = MemoryJobStore();
      final queue = JobQueue(store: store);
      queue.handle('x', (job) async {});

      await queue.add('x', {});
      // Reserve manually with a tiny lease, then let it expire without ack.
      final reserved = await store.reserve(const Duration(milliseconds: 30));
      expect(reserved, isNotNull);
      expect((await store.stats()).active, 1);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      final recovered = await store.sweep();
      expect(recovered, 1);
      expect((await store.stats()).active, 0);
      expect((await store.stats()).ready, 1);

      await queue.close();
    });
  });
}
