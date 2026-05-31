import 'package:darto/darto.dart';
import 'package:darto_env/darto_env.dart';
import 'package:darto_jobs/darto_jobs.dart';
import 'package:darto_mailer/darto_mailer.dart';

void main() async {
  DartoEnv.load();

  final mailer = Mailer(
    from: DartoEnv.maybeGet('MAIL_FROM') ?? 'no-reply@example.com',
    transport: SmtpTransport(
      host: DartoEnv.maybeGet('SMTP_HOST') ?? 'sandbox.smtp.mailtrap.io',
      port: DartoEnv.maybeGet('SMTP_PORT') != null
          ? int.parse(DartoEnv.get('SMTP_PORT'))
          : 2525,
      username: DartoEnv.maybeGet('SMTP_USER') ?? '',
      password: DartoEnv.maybeGet('SMTP_PASS') ?? '',
      security: SmtpSecurity.starttls,
    ),
  );

  // In-process store. For durability + multiple worker processes, swap for:
  //   final queue = JobQueue(store: await RedisJobStore.connect(host: 'localhost'));
  final queue = JobQueue(store: MemoryJobStore());

  // Register a handler — throws → retry with exponential backoff;
  // after maxAttempts the job is dead-lettered and onFailed fires.
  queue.handle('send-welcome', (job) async {
    final email = job.data['email'] as String;
    print('[job] sending welcome to $email (attempt ${job.attempts})');
    await mailer.send(Message(
      to: email,
      subject: 'Welcome to Darto!',
      text: 'Thanks for signing up.',
      html: '<h1>Welcome!</h1><p>Thanks for signing up.</p>',
    ));
    print('[job] welcome email sent to $email');
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

  app.get('/stats', [],
      (Context c) async => c.ok((await queue.store.stats()).toString()));

  app.listen(3000, () => print('Jobs example on http://localhost:3000'));
}
