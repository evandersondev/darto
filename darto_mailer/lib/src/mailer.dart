import 'message.dart';
import 'transport.dart';

/// The email sender — owns a default `from` address and a [MailTransport].
///
/// ```dart
/// final mailer = Mailer(
///   from: 'no-reply@example.com',
///   transport: SmtpTransport(host: 'smtp.example.com', ...),
/// );
///
/// await mailer.send(Message(
///   to: 'user@example.com',
///   subject: 'Welcome',
///   html: '<h1>Hello!</h1>',
/// ));
/// ```
class Mailer {
  /// Default sender used when a [Message] doesn't set its own `from`.
  final String from;

  /// Where messages actually go — SMTP, console, memory, …
  final MailTransport transport;

  Mailer({required this.from, required this.transport});

  /// Validates [message] and hands it to the [transport].  Throws
  /// [ArgumentError] when there are no recipients or no body.
  Future<void> send(Message message) {
    if (message.to.isEmpty && message.cc.isEmpty && message.bcc.isEmpty) {
      throw ArgumentError('Message has no recipients (to/cc/bcc are all empty)');
    }
    if (message.text == null && message.html == null && message.attachments.isEmpty) {
      throw ArgumentError('Message has no body (set text, html or attachments)');
    }
    return transport.send(message, from: message.from ?? from);
  }

  /// Releases the underlying transport's resources.
  Future<void> close() => transport.close();
}
