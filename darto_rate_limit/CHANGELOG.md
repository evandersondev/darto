## 1.0.0

- Initial release.
- `RedisRateLimitStore` — distributed [`RateLimitStore`] backend, drop-in for
  the core `rateLimit()` middleware.  Uses a single Lua script per hit
  (`INCR` + conditional `PEXPIRE` + `PTTL`) so concurrent hits from multiple
  instances always agree on the same window.
- `prefix` parameter to namespace keys (defaults to `'rl:'`).
- `close()` releases the underlying connection.
