## 1.0.0

- Initial release.
- `Cache` interface: `get / set / delete / has / clear / close` — small,
  async, prefix-aware.
- `MemoryCache` — zero-dep in-process cache with lazy TTL expiry and
  optional LRU eviction (`maxEntries`).  O(1) lookup and write.
- `RedisCache` — distributed adapter on top of the `redis` driver
  (pure-Dart).  JSON codec for values, key prefixing, prefix-scoped
  `clear()` via `SCAN` + batched `DEL` (or `FLUSHDB` when unprefixed).
- `cache.remember(key, {ttl, builder})` — read-through helper.
