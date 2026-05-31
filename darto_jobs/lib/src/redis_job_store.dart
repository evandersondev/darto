import 'package:redis/redis.dart';

import 'job.dart';
import 'job_store.dart';

/// Durable, shared [JobStore] backed by Redis with **at-least-once** delivery.
///
/// Layout (all keys share [prefix]):
/// - `ready`      — LIST of job JSON, FIFO.
/// - `delayed`    — ZSET (member = job JSON, score = scheduledAt ms).
/// - `processing` — HASH (id → job JSON) of leased jobs.
/// - `leases`     — ZSET (member = id, score = lease-expiry ms).
/// - `dead`       — LIST of job JSON that exhausted its attempts.
///
/// `reserve` runs a Lua script that promotes due delayed jobs, pops the next
/// ready job and leases it — all atomically.  `sweep` re-queues jobs whose
/// lease expired (e.g. a crashed worker).
class RedisJobStore implements JobStore {
  RedisJobStore._(this._conn, this._cmd, this.prefix);

  final RedisConnection _conn;
  final Command _cmd;

  /// Key prefix — lets multiple queues share one Redis (default `darto_jobs:`).
  final String prefix;

  String get _ready => '${prefix}ready';
  String get _delayed => '${prefix}delayed';
  String get _processing => '${prefix}processing';
  String get _leases => '${prefix}leases';
  String get _dead => '${prefix}dead';

  static Future<RedisJobStore> connect({
    String host = 'localhost',
    int port = 6379,
    String prefix = 'darto_jobs:',
  }) async {
    final conn = RedisConnection();
    final cmd = await conn.connect(host, port);
    return RedisJobStore._(conn, cmd, prefix);
  }

  int _now() => DateTime.now().millisecondsSinceEpoch;

  @override
  Future<void> enqueue(StoredJob job) async {
    final json = job.toJsonString();
    if (job.scheduledAtMs <= _now()) {
      await _cmd.send_object(['RPUSH', _ready, json]);
    } else {
      await _cmd.send_object(['ZADD', _delayed, '${job.scheduledAtMs}', json]);
    }
  }

  static const _reserveScript = '''
local due = redis.call('ZRANGEBYSCORE', KEYS[2], '-inf', ARGV[1])
for _, j in ipairs(due) do
  redis.call('RPUSH', KEYS[1], j)
  redis.call('ZREM', KEYS[2], j)
end
local job = redis.call('LPOP', KEYS[1])
if not job then return nil end
local id = cjson.decode(job)['id']
redis.call('HSET', KEYS[3], id, job)
redis.call('ZADD', KEYS[4], ARGV[2], id)
return job''';

  @override
  Future<StoredJob?> reserve(Duration lease) async {
    final now = _now();
    final res = await _cmd.send_object([
      'EVAL',
      _reserveScript,
      '4',
      _ready,
      _delayed,
      _processing,
      _leases,
      '$now',
      '${now + lease.inMilliseconds}',
    ]);
    if (res == null) return null;
    return StoredJob.fromJsonString(res as String);
  }

  @override
  Future<void> ack(String id) async {
    await _cmd.send_object(['HDEL', _processing, id]);
    await _cmd.send_object(['ZREM', _leases, id]);
  }

  @override
  Future<void> retry(StoredJob job) async {
    await _cmd.send_object(['HDEL', _processing, job.id]);
    await _cmd.send_object(['ZREM', _leases, job.id]);
    await _cmd.send_object(
        ['ZADD', _delayed, '${job.scheduledAtMs}', job.toJsonString()]);
  }

  @override
  Future<void> fail(StoredJob job) async {
    await _cmd.send_object(['HDEL', _processing, job.id]);
    await _cmd.send_object(['ZREM', _leases, job.id]);
    await _cmd.send_object(['RPUSH', _dead, job.toJsonString()]);
  }

  static const _sweepScript = '''
local expired = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', ARGV[1])
local n = 0
for _, id in ipairs(expired) do
  local job = redis.call('HGET', KEYS[2], id)
  if job then
    redis.call('RPUSH', KEYS[3], job)
    redis.call('HDEL', KEYS[2], id)
  end
  redis.call('ZREM', KEYS[1], id)
  n = n + 1
end
return n''';

  @override
  Future<int> sweep() async {
    final res = await _cmd.send_object([
      'EVAL',
      _sweepScript,
      '3',
      _leases,
      _processing,
      _ready,
      '${_now()}',
    ]);
    return (res as int?) ?? 0;
  }

  @override
  Future<JobStats> stats() async {
    final ready = await _cmd.send_object(['LLEN', _ready]) as int;
    final delayed = await _cmd.send_object(['ZCARD', _delayed]) as int;
    final active = await _cmd.send_object(['HLEN', _processing]) as int;
    final dead = await _cmd.send_object(['LLEN', _dead]) as int;
    return JobStats(ready: ready, delayed: delayed, active: active, dead: dead);
  }

  @override
  Future<List<StoredJob>> deadLetter() async {
    final res = await _cmd.send_object(['LRANGE', _dead, '0', '-1']) as List;
    return res.map((e) => StoredJob.fromJsonString(e as String)).toList();
  }

  @override
  Future<void> close() => _conn.close();
}
