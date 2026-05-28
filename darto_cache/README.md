<br>

<p align="center">
  <img src="https://raw.githubusercontent.com/evandersondev/darto/main/imgs/darto-logo.png" alt="Darto Logo" width="200"/>
</p>

<br>

# darto_cache

Cache primitives for the [Darto](https://pub.dev/packages/darto) ecosystem —
a tiny `Cache` interface, a zero-dep `MemoryCache` (LRU + TTL) and a
`RedisCache` adapter for shared / distributed caching.

## Install

```yaml
dependencies:
  darto_cache: ^1.0.0
```

## Quick start

```dart
import 'package:darto_cache/darto_cache.dart';

// In-process — zero deps, LRU optional
final cache = MemoryCache(maxEntries: 1024);

// Or shared / distributed
final cache = await RedisCache.connect(
  host: 'localhost',
  port: 6379,
  prefix: 'app:',
);

await cache.set('user:42', {'name': 'Eva'}, ttl: Duration(minutes: 5));
final user = await cache.get<Map<String, dynamic>>('user:42');

// Read-through — the helper you actually want
final post = await cache.remember<Map<String, dynamic>>(
  'post:$id',
  ttl: Duration(minutes: 1),
  builder: () => db.posts.findById(id),
);
```

`cache.remember` calls `builder` on miss, stores the result with [ttl], and
returns it.  **`null` is not cached** — if `builder` returns null the next
call will rebuild.

## With `darto_di`

```dart
final cacheProvider = AsyncProvider<Cache>(
  (di) => RedisCache.connect(
    host: di.read(envProvider).redisHost,
    prefix: 'app:',
  ),
  onDispose: (c) => c.close(),
);

app.get('/users/:id', [], (c) async {
  final cache = await c.readAsync(cacheProvider);
  final user = await cache.remember(
    'user:${c.req.param('id')}',
    ttl: Duration(minutes: 5),
    builder: () => userService.findById(c.req.param('id')!),
  );
  return c.ok(user);
});
```

## API

| Member | Description |
|---|---|
| `Cache` | Interface: `get / set / delete / has / clear / close` |
| `cache.remember(key, {ttl, builder})` | Read-through helper |
| `MemoryCache({maxEntries})` | In-process cache; LRU when `maxEntries` is set |
| `RedisCache.connect({host, port, prefix})` | Distributed cache over Redis |

### `RedisCache` notes

- Values are JSON-encoded; everything `jsonEncode` accepts round-trips.
- `prefix` is prepended to every key — `clear()` only drops keys under that
  prefix (via `SCAN` + batched `DEL`).  When `prefix` is empty, `clear()`
  runs `FLUSHDB` and wipes the whole database.
- `set` with a `ttl` uses `SET key value PX <ms>` — sub-second TTLs round-trip.

## Testing the Redis adapter

The included Redis test suite is tagged `redis` and boots a disposable
container on a random host port:

```sh
dart test --tags redis     # only Redis suite
dart test                  # everything (incl. Redis if Docker is up)
```

`docker` must be on the PATH and able to pull (or already have) the
`redis:latest` image.

<br/>

---

<br/>

### Support 💖

If you find Darto Cache useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟
