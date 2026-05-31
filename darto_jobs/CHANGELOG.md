## 1.0.0

- Initial release.
- `JobQueue` — `add()` (immediate / `delay` / `scheduledAt`), `handle()`,
  `work()`, `onFailed()`.
- `Worker` — bounded `concurrency`, polling loop, periodic lease sweep and a
  graceful `stop()` that drains in-flight jobs.
- Retry with configurable `maxAttempts` + `backoff` (exponential by default);
  exhausted jobs move to the dead-letter list.
- `MemoryJobStore` — zero-dep in-process store for dev / tests.
- `RedisJobStore` — durable, shared store with **at-least-once** delivery:
  atomic `reserve` (Lua) that promotes due delayed jobs and leases the next
  ready one, plus `sweep` that recovers jobs from crashed workers.
- `JobStore` interface for custom backends; `JobStats` for queue depth.
