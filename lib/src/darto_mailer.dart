import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mustache_template/mustache.dart';

class DartoMailer {
  bool _isConfigured = false;

  DartoTransporter createTransport({
    required String host,
    required int port,
    required bool ssl,
    required Map<String, String> auth,
    bool allowInsecure = false,
  }) {
    if (auth['username'] == null || auth['password'] == null) {
      throw Exception('Authentication credentials are required');
    }

    final smtpServer = SmtpServer(
      host,
      port: port,
      ssl: ssl,
      allowInsecure: allowInsecure,
      username: auth['username']!,
      password: auth['password']!,
    );

    _isConfigured = true;

    if (!_isConfigured) {
      throw Exception('SMTP server is not configured');
    }

    return DartoTransporter(smtpServer, _isConfigured);
  }
}

class DartoTransporter {
  final SmtpServer _smtpServer;
  final bool _isConfigured;
  final _emailQueue = Queue<_EmailTask>();
  bool _isSending = false;

  DartoTransporter(this._smtpServer, isConfigured)
      : _isConfigured = isConfigured;

  Future<bool> sendMail({
    required String from,
    required String to,
    required String subject,
    String? text,
    String? html,
    List<File>? attachments,
    List<String>? cc,
    List<String>? bcc,
  }) async {
    if (!_isConfigured) {
      throw Exception(
          'Email transport not configured. Call createTransport first.');
    }

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

    if (cc != null) {
      message.ccRecipients.addAll(cc);
    }

    if (bcc != null) {
      message.bccRecipients.addAll(bcc);
    }

    _enqueueEmail(_EmailTask(message));
    return true;
  }

  void _enqueueEmail(_EmailTask task) {
    _emailQueue.add(task);
    if (!_isSending) {
      _processQueue();
    }
  }

  void _processQueue() async {
    _isSending = true;
    while (_emailQueue.isNotEmpty) {
      final task = _emailQueue.removeFirst();
      try {
        await send(task.message, _smtpServer);
        print('Email sent: ${task.message.subject}');
      } catch (e) {
        print('Error sending email: $e');
      }
    }
    _isSending = false;
  }

  String renderTemplate(String template, Map<String, dynamic> values) {
    final mustacheTemplate = Template(template);
    return mustacheTemplate.renderString(values);
  }

  bool validateEmail(String email) {
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegExp.hasMatch(email);
  }
}

class _EmailTask {
  final Message message;
  _EmailTask(this.message);
}
