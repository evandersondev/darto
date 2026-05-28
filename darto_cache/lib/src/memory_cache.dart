import 'cache.dart';

class _Entry {
  _Entry(this.value, this.expiresAt);
  final Object? value;
  final DateTime? expiresAt;
  bool get expired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// In-memory [Cache] with **lazy TTL expiry** and optional **LRU eviction**.
///
/// Lookups are O(1).  When [maxEntries] is set, inserting past the limit
/// evicts the least-recently-used key — both writes and reads update the
/// recency, mirroring a textbook LRU.
///
/// ```dart
/// final cache = MemoryCache(maxEntries: 1024);
/// await cache.set('user:42', {'name': 'Eva'}, ttl: Duration(minutes: 5));
/// final user = await cache.get<Map<String, dynamic>>('user:42');
/// ```
class MemoryCache implements Cache {
  /// Maximum number of live entries before LRU eviction kicks in.  Leave
  /// `null` for an unbounded cache (useful in tests and small in-process maps).
  final int? maxEntries;

  // `Map<K,V>` preserves insertion order — and re-inserting on access turns
  // it into a recency list (newest is last; oldest is first).
  final Map<String, _Entry> _entries = <String, _Entry>{};

  MemoryCache({this.maxEntries});

  @override
  Future<T?> get<T>(String key) async {
    final e = _entries.remove(key);
    if (e == null) return null;
    if (e.expired) return null; // dropped above; do not re-insert
    _entries[key] = e; // move to most-recent end
    return e.value as T?;
  }

  @override
  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    _entries.remove(key);
    _entries[key] = _Entry(
      value,
      ttl == null ? null : DateTime.now().add(ttl),
    );
    if (maxEntries != null) _evictIfNeeded();
  }

  @override
  Future<bool> delete(String key) async {
    return _entries.remove(key) != null;
  }

  @override
  Future<bool> has(String key) async {
    final e = _entries[key];
    if (e == null) return false;
    if (e.expired) {
      _entries.remove(key);
      return false;
    }
    return true;
  }

  @override
  Future<void> clear() async => _entries.clear();

  @override
  Future<void> close() async => _entries.clear();

  void _evictIfNeeded() {
    while (_entries.length > maxEntries!) {
      _entries.remove(_entries.keys.first);
    }
  }
}
