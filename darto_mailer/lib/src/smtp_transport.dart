import 'dart:io';

import 'package:mailer/mailer.dart' as m;
import 'package:mailer/smtp_server.dart';

import 'message.dart';
import 'transport.dart';

/// Connection security for [SmtpTransport].
enum SmtpSecurity {
  /// Plain connection, no TLS.  Used by local test servers (Mailpit/MailHog).
  none,

  /// Implicit TLS from the first byte — typically port 465.
  ssl,

  /// Connect plain, then upgrade with the `STARTTLS` command — typically port
  /// 587.  This is the default and the safest for most providers.
  starttls,
}

/// Production [MailTransport] that speaks SMTP, backed by the pure-Dart
/// `mailer` package.
///
/// ```dart
/// final transport = SmtpTransport(
///   host: 'smtp.gmail.com',
///   port: 587,
///   username: env.smtpUser,
///   password: env.smtpPass,
///   security: SmtpSecurity.starttls,
/// );
/// ```
class SmtpTransport implements MailTransport {
  final SmtpServer _server;

  SmtpTransport({
    required String host,
    int port = 587,
    String? username,
    String? password,
    SmtpSecurity security = SmtpSecurity.starttls,
    bool ignoreBadCertificate = false,
    String? xoauth2Token,
  }) : _server = SmtpServer(
          host,
          port: port,
          username: username,
          password: password,
          ssl: security == SmtpSecurity.ssl,
          // `allowInsecure` lets the library proceed over a plain connection
          // when STARTTLS isn't available — required for none.
          allowInsecure: security == SmtpSecurity.none,
          ignoreBadCertificate: ignoreBadCertificate,
          xoauth2Token: xoauth2Token,
        );

  @override
  Future<void> send(Message message, {required String from}) async {
    await m.send(_toMailerMessage(message, from), _server);
  }

  @override
  Future<void> close() async {}

  m.Message _toMailerMessage(Message msg, String from) {
    final out = m.Message()
      ..from = m.Address(from)
      ..recipients.addAll(msg.to)
      ..ccRecipients.addAll(msg.cc)
      ..bccRecipients.addAll(msg.bcc)
      ..subject = msg.subject
      ..text = msg.text
      ..html = msg.html
      ..attachments.addAll(msg.attachments.map(_toMailerAttachment));
    if (msg.replyTo != null) out.headers['Reply-To'] = msg.replyTo!;
    msg.headers.forEach((k, v) => out.headers[k] = v);
    return out;
  }

  m.Attachment _toMailerAttachment(Attachment a) {
    if (a.path != null) {
      return m.FileAttachment(
        File(a.path!),
        fileName: a.filename,
        contentType: a.contentType,
      );
    }
    if (a.content != null) {
      return m.StringAttachment(
        a.content!,
        fileName: a.filename,
        contentType: a.contentType,
      );
    }
    return m.StreamAttachment(
      Stream<List<int>>.value(a.bytes ?? const <int>[]),
      a.contentType ?? 'application/octet-stream',
      fileName: a.filename,
    );
  }
}
