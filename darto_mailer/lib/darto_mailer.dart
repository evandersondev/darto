/// Email sending for the Darto ecosystem.
///
/// ```dart
/// import 'package:darto_mailer/darto_mailer.dart';
///
/// final mailer = Mailer(
///   from: 'no-reply@example.com',
///   transport: SmtpTransport(
///     host: 'smtp.example.com',
///     port: 587,
///     username: env.smtpUser,
///     password: env.smtpPass,
///   ),
/// );
///
/// await mailer.send(Message(
///   to: 'user@example.com',
///   subject: 'Welcome',
///   text: 'Hello!',
///   html: '<h1>Hello!</h1>',
/// ));
/// ```
library;

export 'src/mailer.dart' show Mailer;
export 'src/message.dart' show Message, Attachment;
export 'src/smtp_transport.dart' show SmtpTransport, SmtpSecurity;
export 'src/transport.dart' show MailTransport, ConsoleTransport, MemoryTransport;
