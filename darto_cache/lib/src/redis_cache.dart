import 'dart:convert';

import 'package:redis/redis.dart';

import 'cache.dart';

/// [Cache] backed by Redis — for shared / distributed caching across
/// processes and hosts.
///
/// Values are serialized with [jsonEncode] on `set` and decoded on `get`, so
/// **anything `jsonEncode` accepts** round-trips (strings, numbers, booleans,
/// nulls, and `Map`/`List` of those).  Pass [prefix] to namespace this cache
/// — `[clear]` will only drop keys under that prefix.
///
/// ```dart
/// final cache = await RedisCache.connect(host: 'localhost', port: 6379, prefix: 'app:');
/// await cache.set('user:42', {'name': 'Eva'}, ttl: Duration(minutes: 5));
/// final user = await cache.get<Map<String, dynamic>>('user:42');
/// await cache.close();
/// ```
class RedisCache implements Cache {
  RedisCache._(this._conn, this._cmd, this.prefix);

  final RedisConnection _conn;
  final Command _cmd;

  /// Prefix prepended to every key, e.g. `'app:'`.  Empty means "no prefix".
  final String prefix;

  /// Opens a TCP connection to a Redis server.
  static Future<RedisCache> connect({
    String host = 'localhost',
    int port = 6379,
    String prefix = '',
  }) async {
    final conn = RedisConnection();
    final cmd = await conn.connect(host, port);
    return RedisCache._(conn, cmd, prefix);
  }

  String _k(String key) => '$prefix$key';

  @override
  Future<T?> get<T>(String key) async {
    final raw = await _cmd.send_object(['GET', _k(key)]);
    if (raw == null) return null;
    return jsonDecode(raw as String) as T?;
  }

  @override
  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    final encoded = jsonEncode(value);
    if (ttl == null) {
      await _cmd.send_object(['SET', _k(key), encoded]);
    } else {
      // PX = milliseconds — finer-grained than EX (seconds), so sub-second
      // TTLs round-trip correctly.
      await _cmd.send_object(
          ['SET', _k(key), encoded, 'PX', '${ttl.inMilliseconds}']);
    }
  }

  @override
  Future<bool> delete(String key) async {
    final n = await _cmd.send_object(['DEL', _k(key)]) as int;
    return n > 0;
  }

  @override
  Future<bool> has(String key) async {
    final n = await _cmd.send_object(['EXISTS', _k(key)]) as int;
    return n > 0;
  }

  /// Drops every key under [prefix].  When [prefix] is empty this calls
  /// `FLUSHDB` — **wipes the whole database**.  Otherwise it iterates with
  /// `SCAN` + batched `DEL`s so it doesn't block the server on big keyspaces.
  @override
  Future<void> clear() async {
    if (prefix.isEmpty) {
      await _cmd.send_object(['FLUSHDB']);
      return;
    }
    var cursor = '0';
    do {
      final res = await _cmd.send_object(
          ['SCAN', cursor, 'MATCH', '$prefix*', 'COUNT', '500']) as List;
      cursor = res[0] as String;
      final keys = (res[1] as List).cast<String>();
      if (keys.isNotEmpty) {
        await _cmd.send_object(['DEL', ...keys]);
      }
    } while (cursor != '0');
  }

  @override
  Future<void> close() => _conn.close();
}
