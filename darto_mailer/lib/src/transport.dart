import 'message.dart';

/// Delivers a [Message] somewhere — SMTP, the console, an in-memory list, …
///
/// A [Mailer] owns one transport and delegates every send to it.  Implement
/// this to add a new backend.
abstract class MailTransport {
  /// Sends [message]; [from] is the resolved sender (per-message override or
  /// the mailer default).
  Future<void> send(Message message, {required String from});

  /// Releases any held resources (open SMTP connections, etc.).
  Future<void> close();
}

/// Transport that prints a human-readable summary instead of sending — handy
/// in development so you can see what *would* go out without a real server.
class ConsoleTransport implements MailTransport {
  /// Sink for the rendered summary.  Defaults to `print`.
  final void Function(String line) output;

  ConsoleTransport({void Function(String)? output}) : output = output ?? print;

  @override
  Future<void> send(Message m, {required String from}) async {
    final b = StringBuffer()
      ..writeln('── Email (ConsoleTransport) ──')
      ..writeln('From:    $from')
      ..writeln('To:      ${m.to.join(', ')}');
    if (m.cc.isNotEmpty) b.writeln('Cc:      ${m.cc.join(', ')}');
    if (m.bcc.isNotEmpty) b.writeln('Bcc:     ${m.bcc.join(', ')}');
    if (m.replyTo != null) b.writeln('ReplyTo: ${m.replyTo}');
    b.writeln('Subject: ${m.subject ?? ''}');
    if (m.attachments.isNotEmpty) {
      b.writeln('Attachments: ${m.attachments.map((a) => a.filename).join(', ')}');
    }
    b.writeln('');
    b.writeln(m.text ?? m.html ?? '(empty body)');
    output(b.toString());
  }

  @override
  Future<void> close() async {}
}

/// Transport that records every send into [sent] without touching the network
/// — use it in tests to assert on outgoing mail.
///
/// ```dart
/// final box = MemoryTransport();
/// final mailer = Mailer(from: 'a@b.com', transport: box);
/// await mailer.send(Message(to: 'x@y.com', subject: 'Hi', text: '…'));
/// expect(box.sent.single.message.subject, 'Hi');
/// ```
class MemoryTransport implements MailTransport {
  /// Every message handed to this transport, in send order, paired with the
  /// resolved sender.
  final List<({String from, Message message})> sent = [];

  @override
  Future<void> send(Message m, {required String from}) async {
    sent.add((from: from, message: m));
  }

  /// Clears the recorded messages.
  void clear() => sent.clear();

  @override
  Future<void> close() async {}
}
