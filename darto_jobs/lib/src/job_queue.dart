import 'dart:async';
import 'dart:math';

import 'job.dart';
import 'job_store.dart';

class _Registration {
  final JobHandler handler;
  final int maxAttempts;
  final BackoffStrategy backoff;
  _Registration(this.handler, this.maxAttempts, this.backoff);
}

/// Default exponential backoff: 2^attempt seconds, capped at one hour.
Duration _defaultBackoff(int attempt) {
  final secs = min(pow(2, attempt).toInt(), 3600);
  return Duration(seconds: secs);
}

/// A background job queue — register handlers, enqueue jobs and start workers.
///
/// ```dart
/// final queue = JobQueue(store: MemoryJobStore());
///
/// queue.handle('send-welcome', (job) async {
///   await mailer.send(Message(to: job.data['email'], subject: 'Welcome'));
/// });
///
/// await queue.add('send-welcome', {'email': 'user@x.com'});
/// final worker = queue.work(concurrency: 4);
/// ```
class JobQueue {
  /// The backing store — `MemoryJobStore` or `RedisJobStore`.
  final JobStore store;

  /// UUID source for new job ids.
  final Random _rng = Random.secure();

  final Map<String, _Registration> _handlers = {};
  JobFailureHook? _onFailed;

  JobQueue({required this.store});

  /// Registers the [handler] for jobs named [name].
  ///
  /// [maxAttempts] (default 3) caps retries; [backoff] computes the delay
  /// before each retry (default exponential).
  void handle(
    String name,
    JobHandler handler, {
    int maxAttempts = 3,
    BackoffStrategy backoff = _defaultBackoff,
  }) {
    _handlers[name] = _Registration(handler, maxAttempts, backoff);
  }

  /// Registers a hook invoked when a job exhausts its attempts and is
  /// dead-lettered.
  void onFailed(JobFailureHook hook) => _onFailed = hook;

  /// Enqueues a job named [name] with [data].
  ///
  /// Pass [delay] to run it later, or [scheduledAt] for an absolute time.
  /// [maxAttempts] overrides the handler's default for this job.
  Future<String> add(
    String name,
    Map<String, dynamic> data, {
    Duration? delay,
    DateTime? scheduledAt,
    int? maxAttempts,
  }) async {
    final id = _uuidV4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final whenMs = scheduledAt?.millisecondsSinceEpoch ??
        (delay == null ? now : now + delay.inMilliseconds);
    final max = maxAttempts ?? _handlers[name]?.maxAttempts ?? 3;
    await store.enqueue(StoredJob(
      id: id,
      name: name,
      data: data,
      attempts: 0,
      maxAttempts: max,
      scheduledAtMs: whenMs,
    ));
    return id;
  }

  /// Starts a [Worker] that polls the store and runs jobs.
  ///
  /// [concurrency] jobs run in parallel; [pollInterval] is how long to wait
  /// when the queue is empty; [lease] is the visibility timeout for a reserved
  /// job before [JobStore.sweep] may recover it.
  Worker work({
    int concurrency = 1,
    Duration pollInterval = const Duration(milliseconds: 200),
    Duration lease = const Duration(seconds: 30),
  }) {
    final worker = Worker._(this, concurrency, pollInterval, lease);
    worker._start();
    return worker;
  }

  /// Releases the store.
  Future<void> close() => store.close();

  Future<void> _process(StoredJob reserved) async {
    final reg = _handlers[reserved.name];
    final job = reserved.toJob();
    if (reg == null) {
      // No handler registered — treat as a failure so it isn't lost silently.
      await store.fail(reserved.copyWith(attempts: reserved.attempts + 1));
      _onFailed?.call(
        job,
        StateError('No handler registered for "${reserved.name}"'),
        StackTrace.current,
      );
      return;
    }
    try {
      await reg.handler(job);
      await store.ack(reserved.id);
    } catch (e, st) {
      final attempt = reserved.attempts + 1; // the attempt that just failed
      if (attempt < reg.maxAttempts) {
        final delayMs = reg.backoff(attempt).inMilliseconds;
        await store.retry(reserved.copyWith(
          attempts: attempt,
          scheduledAtMs: DateTime.now().millisecondsSinceEpoch + delayMs,
        ));
      } else {
        await store.fail(reserved.copyWith(attempts: attempt));
        _onFailed?.call(job, e, st);
      }
    }
  }

  String _uuidV4() {
    final b = List<int>.generate(16, (_) => _rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
    return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
        '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
  }
}

/// Polls a [JobQueue]'s store and runs jobs with bounded concurrency.  Start
/// one with `queue.work(...)`; stop it (draining in-flight jobs) with [stop].
class Worker {
  Worker._(this._queue, this._concurrency, this._pollInterval, this._lease);

  final JobQueue _queue;
  final int _concurrency;
  final Duration _pollInterval;
  final Duration _lease;

  bool _running = false;
  final List<Future<void>> _loops = [];
  Timer? _sweepTimer;

  void _start() {
    _running = true;
    for (var i = 0; i < _concurrency; i++) {
      _loops.add(_loop());
    }
    // Periodically recover jobs whose lease expired (crash recovery).
    final period =
        Duration(milliseconds: max(1000, _lease.inMilliseconds ~/ 2));
    _sweepTimer = Timer.periodic(period, (_) {
      _queue.store.sweep();
    });
  }

  Future<void> _loop() async {
    while (_running) {
      StoredJob? reserved;
      try {
        reserved = await _queue.store.reserve(_lease);
      } catch (_) {
        reserved = null;
      }
      if (reserved == null) {
        await Future<void>.delayed(_pollInterval);
        continue;
      }
      await _queue._process(reserved);
    }
  }

  /// Stops polling and waits for in-flight jobs to finish.
  Future<void> stop() async {
    _running = false;
    _sweepTimer?.cancel();
    await Future.wait(_loops);
    _loops.clear();
  }
}
