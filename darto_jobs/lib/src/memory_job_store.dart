import 'job.dart';
import 'job_store.dart';

/// In-process [JobStore] — zero dependencies, ideal for development, tests and
/// single-process apps.  State lives in memory, so jobs do not survive a
/// process restart (use `RedisJobStore` for durability).
///
/// Lease/sweep is implemented for interface parity; in a single isolate a
/// crashed handler takes the whole process down, so it mainly recovers jobs
/// whose handler exceeded the lease.
class MemoryJobStore implements JobStore {
  final List<StoredJob> _pending = [];
  final Map<String, _Leased> _processing = {};
  final List<StoredJob> _dead = [];

  int _now() => DateTime.now().millisecondsSinceEpoch;

  @override
  Future<void> enqueue(StoredJob job) async {
    _pending.add(job);
  }

  @override
  Future<StoredJob?> reserve(Duration lease) async {
    final now = _now();
    final idx = _pending.indexWhere((j) => j.scheduledAtMs <= now);
    if (idx == -1) return null;
    final job = _pending.removeAt(idx);
    _processing[job.id] = _Leased(job, now + lease.inMilliseconds);
    return job;
  }

  @override
  Future<void> ack(String id) async {
    _processing.remove(id);
  }

  @override
  Future<void> retry(StoredJob job) async {
    _processing.remove(job.id);
    _pending.add(job);
  }

  @override
  Future<void> fail(StoredJob job) async {
    _processing.remove(job.id);
    _dead.add(job);
  }

  @override
  Future<int> sweep() async {
    final now = _now();
    final expired =
        _processing.entries.where((e) => e.value.leaseExpiryMs <= now).toList();
    for (final e in expired) {
      _processing.remove(e.key);
      _pending.add(e.value.job);
    }
    return expired.length;
  }

  @override
  Future<JobStats> stats() async {
    final now = _now();
    final ready = _pending.where((j) => j.scheduledAtMs <= now).length;
    return JobStats(
      ready: ready,
      delayed: _pending.length - ready,
      active: _processing.length,
      dead: _dead.length,
    );
  }

  @override
  Future<List<StoredJob>> deadLetter() async => List.unmodifiable(_dead);

  @override
  Future<void> close() async {
    _pending.clear();
    _processing.clear();
    _dead.clear();
  }
}

class _Leased {
  final StoredJob job;
  final int leaseExpiryMs;
  _Leased(this.job, this.leaseExpiryMs);
}
