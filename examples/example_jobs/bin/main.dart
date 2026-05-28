import 'package:darto/darto.dart';
import 'package:darto_jobs/darto_jobs.dart';

void main() async {
  // In-process store. For durability + multiple worker processes, swap for:
  //   final queue = JobQueue(store: await RedisJobStore.connect(host: 'localhost'));
  final queue = JobQueue(store: MemoryJobStore());

  // Register a handler by job name. Throwing triggers a retry with backoff;
  // after maxAttempts the job is dead-lettered.
  queue.handle('send-welcome', (job) async {
    print('[job] sending welcome to ${job.data['email']} (attempt ${job.attempts})');
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }, maxAttempts: 3);

  queue.onFailed((job, error, _) => print('[job] ${job.name} gave up: $error'));

  // Start a worker in the same process (production: a separate `dart run`).
  queue.work(concurrency: 2);

  final app = Darto();

  // Respond immediately; the email goes out in the background.
  app.post('/signup', [], (Context c) async {
    final body = await c.req.json();
    final id = await queue.add('send-welcome', {'email': body['email']});
    return c.created({'queued': id});
  });

  // Run a job 5s from now.
  app.post('/remind', [], (Context c) async {
    final body = await c.req.json();
    await queue.add('send-welcome', {'email': body['email']},
        delay: const Duration(seconds: 5));
    return c.status(202).json({'scheduled': true});
  });

  app.get('/stats', [], (Context c) async => c.ok((await queue.store.stats()).toString()));

  await app.listen(3000, () => print('Jobs example on http://localhost:3000'));
  // On shutdown you'd drain the worker and close the store:
  //   await worker.stop();
  //   await queue.close();
}
