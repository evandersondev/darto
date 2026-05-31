# example_rate_limit

Distributed rate limiting with [`darto_rate_limit`](../../darto_rate_limit/).

## What it shows
- The core `rateLimit()` middleware (5 req / 10s per IP) with `RateLimit-*` headers + `429` + `Retry-After`.
- Swapping the in-memory store for `RedisRateLimitStore` so the limit is shared across replicas — controlled here by the `REDIS_HOST` env var.

## Run
```bash
# In-memory (single instance):
dart run bin/main.dart

# Distributed — share the counter across instances via Redis:
REDIS_HOST=localhost dart run bin/main.dart

# Trip the limit:
for i in $(seq 1 7); do curl -s -o /dev/null -w "%{http_code}\n" localhost:3000/; done
# → 200 200 200 200 200 429 429
```
