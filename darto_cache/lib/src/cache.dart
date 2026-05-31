/// A small, async key-value cache — backed by memory or by Redis.
///
/// Values are anything `jsonEncode` can round-trip (strings, numbers, booleans,
/// nulls, and `Map`/`List` of those).  `get<T>()` returns `null` for both
/// "key wasn't there" and "key expired" — readers shouldn't try to tell them
/// apart.
abstract class Cache {
  /// Returns the cached value, or `null` when the key is absent or expired.
  Future<T?> get<T>(String key);

  /// Stores [value] under [key], replacing any previous entry.  When [ttl] is
  /// `null` the entry has no expiration; readers may still evict it (LRU).
  Future<void> set<T>(String key, T value, {Duration? ttl});

  /// Removes [key].  Returns `true` if it was present, `false` otherwise.
  Future<bool> delete(String key);

  /// Whether [key] is currently present (and unexpired).
  Future<bool> has(String key);

  /// Drops every entry the cache owns.  For prefix-scoped backends (Redis with
  /// a configured prefix), this only affects keys under that prefix.
  Future<void> clear();

  /// Releases underlying resources (Redis connection, timers, etc.).
  Future<void> close();
}

/// Read-through helper — the call site you actually want most of the time.
///
/// ```dart
/// final user = await cache.remember<Map<String, dynamic>>(
///   'user:$id',
///   ttl: Duration(minutes: 5),
///   builder: () => db.users.findById(id),
/// );
/// ```
///
/// On hit: returns the cached value (no `builder` call).  On miss: calls
/// [builder], stores the result under [key] with [ttl], returns it.
///
/// **`null` is not cached.**  If [builder] returns `null` we just return it
/// without `set` — the next call will rebuild.  Cache the "not found" sentinel
/// of your choice (e.g. `{}` or `false`) if you need negative caching.
extension CacheRemember on Cache {
  Future<T?> remember<T>(
    String key, {
    Duration? ttl,
    required Future<T?> Function() builder,
  }) async {
    final hit = await get<T>(key);
    if (hit != null) return hit;
    final fresh = await builder();
    if (fresh != null) await set<T>(key, fresh, ttl: ttl);
    return fresh;
  }
}
