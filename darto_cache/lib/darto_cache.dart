/// Cache primitives for the Darto ecosystem — a tiny [Cache] interface with
/// a zero-dep [MemoryCache] (LRU + TTL) and a [RedisCache] adapter for
/// distributed caching.
///
/// ```dart
/// import 'package:darto_cache/darto_cache.dart';
///
/// final cache = MemoryCache(maxEntries: 1000);
/// final user  = await cache.remember(
///   'user:$id',
///   ttl: Duration(minutes: 5),
///   builder: () => db.users.findById(id),
/// );
/// ```
library;

export 'src/cache.dart' show Cache, CacheRemember;
export 'src/memory_cache.dart' show MemoryCache;
export 'src/redis_cache.dart' show RedisCache;
