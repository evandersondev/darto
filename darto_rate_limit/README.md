<br>

<p align="center">
  <img src="https://raw.githubusercontent.com/evandersondev/darto/main/imgs/darto-logo.png" alt="Darto Logo" width="200"/>
</p>

<br>

# darto_rate_limit

Distributed [`RateLimitStore`](https://pub.dev/documentation/darto/latest/rate_limit/RateLimitStore-class.html)
backends for the [Darto](https://pub.dev/packages/darto) framework's core
`rateLimit()` middleware — share the same counter across every app instance.

The core ships with an in-process `MemoryRateLimitStore` (zero-dep, perfect for
a single instance).  This package adds **`RedisRateLimitStore`** so the same
limit applies when you're running multiple replicas behind a load balancer.

## Install

```yaml
dependencies:
  darto: ^1.2.0
  darto_rate_limit: ^1.0.0
```

## Usage

```dart
import 'package:darto/darto.dart';
import 'package:darto/rate_limit.dart';
import 'package:darto_rate_limit/darto_rate_limit.dart';

void main() async {
  final store = await RedisRateLimitStore.connect(
    host: 'localhost',
    port: 6379,
    prefix: 'rl:',
  );

  final app = Darto()
    ..use(rateLimit(
      max: 100,
      window: Duration(minutes: 1),
      store: store, // ← all instances share this counter
    ));

  await app.listen(3000);
  await store.close();
}
```

## How it works

Each `hit(key)` runs a tiny Lua script in a **single round-trip**, so the
counter is correct under concurrent hits from many app instances:

```
local n = redis.call('INCR', KEYS[1])
if n == 1 then redis.call('PEXPIRE', KEYS[1], ARGV[1]) end
return { n, redis.call('PTTL', KEYS[1]) }
```

- `INCR` is atomic — counts are never lost.
- `PEXPIRE` only fires when the window starts, so every instance agrees on
  the same `resetAt`.
- One round-trip per request — no race, no extra latency vs the memory store.

## Tests

```sh
dart test --tags redis
```

The included suite boots a disposable `redis:latest` container on a random
host port (`docker` must be available).

<br/>

---

<br/>

### Support 💖

If you find Darto Rate-Limit useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟
