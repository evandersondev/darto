import 'dart:convert';

/// The handler invoked for each reserved job.  Throw to trigger a retry (or a
/// move to the dead-letter list once attempts are exhausted).
typedef JobHandler = Future<void> Function(Job job);

/// Computes the delay before the next attempt, given the 1-based [attempt] that
/// just failed.  Default is exponential: 2^attempt seconds, capped at 1 hour.
typedef BackoffStrategy = Duration Function(int attempt);

/// Called when a job exhausts its attempts and lands in the dead-letter list.
typedef JobFailureHook = void Function(Job job, Object error, StackTrace stack);

/// The handler-facing view of a job.
class Job {
  /// Unique job id.
  final String id;

  /// The job name — selects the registered handler.
  final String name;

  /// The JSON-serializable payload passed to [JobHandler].
  final Map<String, dynamic> data;

  /// 1-based number of the *current* attempt (1 on the first run).
  final int attempts;

  /// Maximum attempts before the job is dead-lettered.
  final int maxAttempts;

  const Job({
    required this.id,
    required this.name,
    required this.data,
    required this.attempts,
    required this.maxAttempts,
  });

  @override
  String toString() => 'Job($name#$id, attempt $attempts/$maxAttempts)';
}

/// The serializable record a [JobStore] persists.  `attempts` here counts
/// *completed* attempts (0 when freshly enqueued); the worker passes
/// `attempts + 1` to the handler as the current attempt number.
class StoredJob {
  final String id;
  final String name;
  final Map<String, dynamic> data;
  final int attempts;
  final int maxAttempts;

  /// Epoch millis when this job becomes eligible to run.
  final int scheduledAtMs;

  const StoredJob({
    required this.id,
    required this.name,
    required this.data,
    required this.attempts,
    required this.maxAttempts,
    required this.scheduledAtMs,
  });

  StoredJob copyWith({int? attempts, int? scheduledAtMs}) => StoredJob(
        id: id,
        name: name,
        data: data,
        attempts: attempts ?? this.attempts,
        maxAttempts: maxAttempts,
        scheduledAtMs: scheduledAtMs ?? this.scheduledAtMs,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'data': data,
        'attempts': attempts,
        'maxAttempts': maxAttempts,
        'scheduledAtMs': scheduledAtMs,
      };

  factory StoredJob.fromJson(Map<String, dynamic> m) => StoredJob(
        id: m['id'] as String,
        name: m['name'] as String,
        data: (m['data'] as Map).cast<String, dynamic>(),
        attempts: m['attempts'] as int,
        maxAttempts: m['maxAttempts'] as int,
        scheduledAtMs: m['scheduledAtMs'] as int,
      );

  String toJsonString() => jsonEncode(toJson());

  factory StoredJob.fromJsonString(String s) =>
      StoredJob.fromJson(jsonDecode(s) as Map<String, dynamic>);

  /// Builds the handler-facing [Job] for the current attempt.
  Job toJob() => Job(
        id: id,
        name: name,
        data: data,
        attempts: attempts + 1,
        maxAttempts: maxAttempts,
      );
}

/// A point-in-time snapshot of queue depth — useful for dashboards / health.
class JobStats {
  /// Jobs ready to run right now.
  final int ready;

  /// Jobs scheduled for the future (delayed / retry backoff).
  final int delayed;

  /// Jobs currently leased by a worker.
  final int active;

  /// Jobs that exhausted their attempts.
  final int dead;

  const JobStats({
    required this.ready,
    required this.delayed,
    required this.active,
    required this.dead,
  });

  @override
  String toString() =>
      'JobStats(ready: $ready, delayed: $delayed, active: $active, dead: $dead)';
}
