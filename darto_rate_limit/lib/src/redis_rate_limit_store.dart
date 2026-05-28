import 'package:darto/rate_limit.dart';
import 'package:redis/redis.dart';

/// Shared / distributed [RateLimitStore] backed by Redis.
///
/// Drop-in replacement for the core's `MemoryRateLimitStore` — counters live
/// on Redis instead of per-process memory, so multiple app instances behind a
/// load balancer agree on the same limit.
///
/// ```dart
/// import 'package:darto/rate_limit.dart';
/// import 'package:darto_rate_limit/darto_rate_limit.dart';
///
/// final store = await RedisRateLimitStore.connect(host: 'localhost', port: 6379);
/// app.use(rateLimit(
///   max: 100,
///   window: Duration(minutes: 1),
///   store: store,
/// ));
/// ```
///
/// **Algorithm.** Each `hit(key)` runs a small Lua script in a single
/// round-trip:
///
/// ```
/// local n = redis.call('INCR', KEYS[1])
/// if n == 1 then redis.call('PEXPIRE', KEYS[1], ARGV[1]) end
/// return {n, redis.call('PTTL', KEYS[1])}
/// ```
///
/// `INCR` is atomic, and the `PEXPIRE` only fires when we started the window,
/// so concurrent hits from different instances always agree on the same
/// `resetAt`.
class RedisRateLimitStore implements RateLimitStore {
  RedisRateLimitStore._(this._conn, this._cmd, this.prefix);

  final RedisConnection _conn;
  final Command _cmd;

  /// Prefix prepended to every key, e.g. `'rl:'`.
  final String prefix;

  /// Opens a connection to a Redis server.
  static Future<RedisRateLimitStore> connect({
    String host = 'localhost',
    int port = 6379,
    String prefix = 'rl:',
  }) async {
    final conn = RedisConnection();
    final cmd = await conn.connect(host, port);
    return RedisRateLimitStore._(conn, cmd, prefix);
  }

  static const _hitScript =
      "local n=redis.call('INCR',KEYS[1])"
      "if n==1 then redis.call('PEXPIRE',KEYS[1],ARGV[1]) end "
      "return {n,redis.call('PTTL',KEYS[1])}";

  @override
  Future<RateLimitHit> hit(String key, Duration window) async {
    final res = await _cmd.send_object([
      'EVAL',
      _hitScript,
      '1',
      '$prefix$key',
      '${window.inMilliseconds}',
    ]) as List;
    final count = res[0] as int;
    final pttl = res[1] as int; // ms until expiry, or -1 if no expiry
    final resetMs = pttl > 0 ? pttl : window.inMilliseconds;
    return RateLimitHit(count, DateTime.now().add(Duration(milliseconds: resetMs)));
  }

  @override
  Future<void> reset(String key) async {
    await _cmd.send_object(['DEL', '$prefix$key']);
  }

  /// Releases the underlying Redis connection.
  Future<void> close() => _conn.close();
}
