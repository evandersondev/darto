<br>

<p align="center">
  <img src="https://raw.githubusercontent.com/evandersondev/darto/main/imgs/darto-logo.png" alt="Darto Logo" width="200"/>
</p>

<br>

# darto_jobs

Background job queue for the [Darto](https://pub.dev/packages/darto) ecosystem
— enqueue work, process it with retries and backoff, backed by an in-memory or
**Redis** store (at-least-once).

## Install

```yaml
dependencies:
  darto_jobs: ^1.0.0
```

## Quick start

```dart
import 'package:darto_jobs/darto_jobs.dart';

final queue = JobQueue(store: MemoryJobStore());            // dev
// final queue = JobQueue(store: await RedisJobStore.connect(host: '...')); // prod

// Register a handler by job name
queue.handle('send-welcome', (job) async {
  final email = job.data['email'] as String;
  await mailer.send(Message(to: email, subject: 'Welcome', html: '…'));
});

// Enqueue from anywhere
await queue.add('send-welcome', {'email': 'user@x.com'});
await queue.add('report', {'id': 42}, delay: Duration(minutes: 5)); // delayed
await queue.add('flaky', {}, maxAttempts: 5);                       // more retries

// Start a worker
final worker = queue.work(concurrency: 4);
// … later, on shutdown:
await worker.stop();   // drains in-flight jobs
```

The worker can run in the same process (dev) or in a **separate process**
(`dart run bin/worker.dart`) pointed at the same Redis — that's how you scale
out.

## Retries, backoff & dead-letter

When a handler throws, the job is re-queued with **exponential backoff** up to
`maxAttempts`; once exhausted it moves to the **dead-letter** list.

```dart
queue.handle('charge', (job) async {
  await payments.charge(job.data['orderId']);
}, maxAttempts: 5, backoff: (attempt) => Duration(seconds: 2 * attempt));

queue.onFailed((job, error, stack) {
  log.error('job ${job.name} (#${job.id}) gave up', error, stack);
});

final dead = await queue.store.deadLetter(); // inspect failures
```

`job.attempts` is the 1-based current attempt; handlers should be **idempotent**
(at-least-once delivery means a job may run more than once on worker crashes).

## With `darto_inject`

```dart
final queueProvider = Provider<JobQueue>(
  (di) => JobQueue(store: di.read(jobStoreProvider)),
  onDispose: (q) => q.close(),
);

app.post('/signup', [], (c) async {
  await c.read(queueProvider).add('send-welcome', {'email': email});
  return c.created({}); // respond fast; the email goes out in the background
});
```

## Delivery guarantee (Redis)

`RedisJobStore` is **at-least-once**:

- `reserve` runs a Lua script that promotes due delayed jobs, pops the next
  ready job and **leases** it (a visibility timeout) — atomically.
- If a worker crashes before `ack`/`retry`/`fail`, the lease expires and the
  periodic `sweep` re-queues the job.
- Competing workers never get the same job twice (atomic `LPOP` + lease).

Keys (under the configurable `prefix`): `ready` (list), `delayed` (zset),
`processing` (hash), `leases` (zset), `dead` (list).

## API

| Type | Purpose |
|---|---|
| `JobQueue({store})` | `add` / `handle` / `work` / `onFailed` / `close` |
| `queue.add(name, data, {delay, scheduledAt, maxAttempts})` | Enqueue a job |
| `queue.handle(name, handler, {maxAttempts, backoff})` | Register a handler |
| `queue.work({concurrency, pollInterval, lease})` | Start a `Worker` |
| `Worker.stop()` | Drain in-flight jobs and stop |
| `Job` | `id / name / data / attempts / maxAttempts` (handler view) |
| `MemoryJobStore` | In-process store (dev / tests) |
| `RedisJobStore.connect({host, port, prefix})` | Durable, shared store |
| `JobStore` | Interface for custom backends |
| `JobStats` | `ready / delayed / active / dead` counts |

## Testing the Redis store

The Redis suite is tagged `redis` and boots a disposable `redis:latest`
container on a random host port:

```sh
dart test --tags redis     # only the Redis suite (needs Docker)
dart test                  # everything (incl. Redis if Docker is up)
```

<br/>

---

<br/>

### Support 💖

If you find Darto Jobs useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟
