import 'dart:io';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class DartoMailer {
  bool _isConfigured = false;

  DartoTransporter createTransport({
    required String host,
    required int port,
    required bool secure,
    required Map<String, String> auth,
  }) {
    if (auth['user'] == null || auth['pass'] == null) {
      throw Exception('Authentication credentials are required');
    }

    final smtpServer = SmtpServer(
      host,
      port: port,
      ssl: secure,
      username: auth['user']!,
      password: auth['pass']!,
    );

    _isConfigured = true;

    if (!_isConfigured) {
      throw Exception('SMTP server is not configured');
    }

    return DartoTransporter(smtpServer);
  }
}

class DartoTransporter {
  final SmtpServer _smtpServer;

  DartoTransporter(this._smtpServer);

  Future<bool> sendMail({
    required String from,
    required String to,
    required String subject,
    String? text,
    String? html,
    List<File>? attachments,
  }) async {
    try {
      final message = Message()
        ..from = Address(from)
        ..recipients.add(to)
        ..subject = subject;

      if (text != null) {
        message.text = text;
      }

      if (html != null) {
        message.html = html;
      }

      if (attachments != null) {
        for (var file in attachments) {
          final attachment = FileAttachment(file);
          message.attachments.add(attachment);
        }
      }

      await send(message, _smtpServer);
      return true;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }
}
