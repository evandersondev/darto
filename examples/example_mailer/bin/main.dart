import 'package:darto/darto.dart';
import 'package:darto_mailer/darto_mailer.dart';

void main() async {
  // ConsoleTransport prints the email instead of sending it — perfect for dev.
  // For real delivery, swap the transport:
  //   transport: SmtpTransport(
  //     host: 'smtp.example.com', port: 587,
  //     username: '...', password: '...',
  //     security: SmtpSecurity.starttls,
  //   ),
  final mailer = Mailer(
    from: 'no-reply@example.com',
    transport: ConsoleTransport(),
  );

  final app = Darto();

  // Respond fast, send the welcome mail as a side effect. In production you'd
  // hand this to darto_jobs so a slow SMTP server never blocks the response.
  app.post('/signup', [], (Context c) async {
    final body = await c.req.json();
    final email = body['email'] as String;

    await mailer.send(Message(
      to: email,
      subject: 'Welcome to Darto!',
      text: 'Thanks for signing up.',
      html: '<h1>Welcome!</h1><p>Thanks for signing up.</p>',
    ));

    return c.created({'email': email});
  });

  await app.listen(
      3000, () => print('Mailer example on http://localhost:3000'));
}
