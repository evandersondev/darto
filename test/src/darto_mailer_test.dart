import 'package:darto/src/darto_mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:test/test.dart';

void main() {
  group('DartoMailer', () {
    late DartoMailer mailer;

    setUp(() {
      mailer = DartoMailer();
    });

    test('createTransport throws exception if auth credentials are missing',
        () {
      expect(
        () => mailer.createTransport(
          host: 'smtp.example.com',
          port: 587,
          ssl: false,
          auth: {},
        ),
        throwsException,
      );
    });

    test('createTransport returns a configured DartoTransporter', () {
      final transporter = mailer.createTransport(
        host: 'smtp.example.com',
        port: 587,
        ssl: false,
        auth: {'username': 'user@example.com', 'password': 'password'},
      );

      expect(transporter, isA<DartoTransporter>());
    });
  });

  group('DartoTransporter', () {
    late DartoTransporter transporter;

    setUp(() {
      final smtpServer = SmtpServer(
        'smtp.example.com',
        port: 587,
        ssl: false,
        username: 'user@example.com',
        password: 'password',
      );
      transporter = DartoTransporter(smtpServer, true);
    });

    test('sendMail throws exception if not configured', () {
      final unconfiguredTransporter = DartoTransporter(
        SmtpServer('smtp.example.com'),
        false,
      );

      expect(
        () => unconfiguredTransporter.sendMail(
          from: 'from@example.com',
          to: 'to@example.com',
          subject: 'Test Email',
        ),
        throwsException,
      );
    });

    test('sendMail enqueues email successfully', () async {
      final result = await transporter.sendMail(
        from: 'from@example.com',
        to: 'to@example.com',
        subject: 'Test Email',
        text: 'This is a test email.',
      );

      expect(result, isTrue);
    });

    test('validateEmail returns true for valid email', () {
      final isValid = transporter.validateEmail('test@example.com');
      expect(isValid, isTrue);
    });

    test('validateEmail returns false for invalid email', () {
      final isValid = transporter.validateEmail('invalid-email');
      expect(isValid, isFalse);
    });

    test('renderTemplate renders template with values', () {
      final template = 'Hello, {{name}}!';
      final rendered = transporter.renderTemplate(template, {'name': 'John'});
      expect(rendered, 'Hello, John!');
    });
  });
}
