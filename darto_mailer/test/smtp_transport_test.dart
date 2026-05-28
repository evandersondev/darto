@Tags(['smtp'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:darto_mailer/darto_mailer.dart';
import 'package:test/test.dart';

/// Boots a disposable Mailpit container — a fake SMTP server that captures
/// every message and exposes them over an HTTP API.  Returns the container id
/// plus the bound SMTP and HTTP ports.
Future<({String id, int smtpPort, int httpPort})> _startMailpit() async {
  Future<int> freePort() async {
    final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final p = s.port;
    await s.close();
    return p;
  }

  final smtpPort = await freePort();
  final httpPort = await freePort();

  final r = await Process.run('docker', [
    'run', '-d', '--rm',
    '-p', '$smtpPort:1025',
    '-p', '$httpPort:8025',
    'axllent/mailpit:latest',
  ]);
  if (r.exitCode != 0) fail('docker run failed: ${r.stderr}');
  final id = (r.stdout as String).trim();

  // Wait for the HTTP API to answer.
  final http = HttpClient();
  for (var i = 0; i < 60; i++) {
    try {
      final req = await http.getUrl(Uri.parse('http://127.0.0.1:$httpPort/api/v1/messages'));
      final res = await req.close();
      await res.drain<void>();
      if (res.statusCode == 200) {
        http.close();
        return (id: id, smtpPort: smtpPort, httpPort: httpPort);
      }
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
  http.close();
  await Process.run('docker', ['rm', '-f', id]);
  fail('Mailpit did not become reachable within ~9s');
}

Future<void> _stop(String id) =>
    Process.run('docker', ['rm', '-f', id]).then((_) {});

/// Fetches Mailpit's captured messages as decoded JSON.
Future<Map<String, dynamic>> _messages(int httpPort) async {
  final http = HttpClient();
  try {
    final req = await http.getUrl(Uri.parse('http://127.0.0.1:$httpPort/api/v1/messages'));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    return jsonDecode(body) as Map<String, dynamic>;
  } finally {
    http.close();
  }
}

void main() {
  late String _id;
  late int _smtpPort;
  late int _httpPort;

  setUpAll(() async {
    final r = await _startMailpit();
    _id = r.id;
    _smtpPort = r.smtpPort;
    _httpPort = r.httpPort;
  });

  tearDownAll(() async => _stop(_id));

  group('SmtpTransport against Mailpit', () {
    test('sends a message that the server captures', () async {
      final mailer = Mailer(
        from: 'no-reply@darto.dev',
        transport: SmtpTransport(
          host: '127.0.0.1',
          port: _smtpPort,
          security: SmtpSecurity.none,
        ),
      );

      await mailer.send(Message(
        to: 'alice@example.com',
        cc: 'bob@example.com',
        subject: 'Hello from Darto',
        text: 'plain body',
        html: '<h1>Hello</h1>',
      ));
      await mailer.close();

      // Give Mailpit a beat to store it.
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final data = await _messages(_httpPort);
      expect(data['total'], greaterThanOrEqualTo(1));
      final msg = (data['messages'] as List).first as Map<String, dynamic>;
      expect(msg['Subject'], 'Hello from Darto');
      expect((msg['From'] as Map)['Address'], 'no-reply@darto.dev');
      final tos = (msg['To'] as List).map((e) => (e as Map)['Address']).toList();
      expect(tos, contains('alice@example.com'));
    });

    test('delivers an attachment', () async {
      final mailer = Mailer(
        from: 'no-reply@darto.dev',
        transport: SmtpTransport(
          host: '127.0.0.1',
          port: _smtpPort,
          security: SmtpSecurity.none,
        ),
      );

      await mailer.send(Message(
        to: 'carol@example.com',
        subject: 'With attachment',
        text: 'see attached',
        attachments: [
          Attachment.string('note.txt', 'hello attachment', contentType: 'text/plain'),
        ],
      ));
      await mailer.close();
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final data = await _messages(_httpPort);
      final withAtt = (data['messages'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((m) => m['Subject'] == 'With attachment');
      expect(withAtt['Attachments'], greaterThanOrEqualTo(1));
    });
  });
}
