/// Background job queue for the Darto ecosystem.
///
/// ```dart
/// import 'package:darto_jobs/darto_jobs.dart';
///
/// final queue = JobQueue(store: MemoryJobStore());
/// queue.handle('send-welcome', (job) async {
///   await mailer.send(Message(to: job.data['email'], subject: 'Welcome'));
/// });
///
/// await queue.add('send-welcome', {'email': 'user@x.com'});
/// final worker = queue.work(concurrency: 4);
/// ```
library;

export 'src/job.dart'
    show Job, StoredJob, JobStats, JobHandler, BackoffStrategy, JobFailureHook;
export 'src/job_queue.dart' show JobQueue, Worker;
export 'src/job_store.dart' show JobStore;
export 'src/memory_job_store.dart' show MemoryJobStore;
export 'src/redis_job_store.dart' show RedisJobStore;
