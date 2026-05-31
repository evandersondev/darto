# example_jobs

Background jobs with [`darto_jobs`](../../darto_jobs/).

## What it shows
- Register a handler with `queue.handle(name, ...)`, enqueue with `queue.add(...)`.
- A `Worker` processing jobs in the background (`queue.work(concurrency: 2)`).
- Delayed jobs (`delay:`), retries/`onFailed`, and `queue.store.stats()`.

## Run
```bash
dart run bin/main.dart

# Enqueue a job — responds instantly, the work happens in the background:
curl -X POST localhost:3000/signup \
  -H 'Content-Type: application/json' -d '{"email":"user@example.com"}'

# Schedule one 5s in the future:
curl -X POST localhost:3000/remind \
  -H 'Content-Type: application/json' -d '{"email":"user@example.com"}'

curl localhost:3000/stats
```

## Durable / distributed
Swap the store for Redis so jobs survive restarts and multiple worker processes
can share the queue (at-least-once):

```dart
final queue = JobQueue(store: await RedisJobStore.connect(host: 'localhost'));
```
