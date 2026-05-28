import 'job.dart';

/// Backing store for a [JobQueue].  Two implementations ship with the package:
/// `MemoryJobStore` (in-process) and `RedisJobStore` (shared, durable,
/// at-least-once).  Implement this to add your own backend.
///
/// The contract is **at-least-once**: [reserve] leases a job for a bounded
/// time; if the worker crashes before [ack]/[retry]/[fail], [sweep] makes the
/// job available again.  Handlers must therefore be idempotent.
abstract class JobStore {
  /// Persists [job], scheduling it for `job.scheduledAtMs`.
  Future<void> enqueue(StoredJob job);

  /// Atomically takes the next job whose `scheduledAtMs <= now`, leasing it for
  /// [lease].  Returns `null` when nothing is ready.
  Future<StoredJob?> reserve(Duration lease);

  /// Marks the leased job [id] as done — removes it from the store.
  Future<void> ack(String id);

  /// Removes the leased job from processing and re-schedules [job] (used for
  /// retry with backoff — [job] carries the new `scheduledAtMs` and bumped
  /// `attempts`).
  Future<void> retry(StoredJob job);

  /// Removes the leased job from processing and moves [job] to the dead-letter
  /// list.
  Future<void> fail(StoredJob job);

  /// Re-queues every job whose lease has expired (crash recovery).  Returns the
  /// number of jobs recovered.
  Future<int> sweep();

  /// Current queue depth.
  Future<JobStats> stats();

  /// The jobs currently in the dead-letter list (exhausted attempts).
  Future<List<StoredJob>> deadLetter();

  /// Releases any resources (Redis connections, timers, …).
  Future<void> close();
}
