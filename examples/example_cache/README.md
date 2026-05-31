# example_cache

Caching with [`darto_cache`](../../darto_cache/).

## What it shows
- `MemoryCache` (LRU + TTL) — swap one line for `RedisCache.connect(...)` to share across instances.
- The **read-through** `cache.remember(key, {ttl, builder})` pattern around a slow lookup.
- Manual `cache.delete(key)` for invalidation.

## Run
```bash
dart run bin/main.dart

# First call is slow (~300ms), the next within 10s is instant + identical:
time curl localhost:3000/users/1
time curl localhost:3000/users/1

# Invalidate, then it's slow again:
curl -X DELETE localhost:3000/users/1
```

## Distributed
For a shared cache across replicas, change the store — the rest stays the same:

```dart
final cache = await RedisCache.connect(host: 'localhost', port: 6379, prefix: 'app:');
```
