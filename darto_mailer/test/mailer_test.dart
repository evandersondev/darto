import 'package:darto_mailer/darto_mailer.dart';
import 'package:test/test.dart';

void main() {
  group('Message', () {
    test('to accepts a single String', () {
      final m = Message(to: 'a@x.com', subject: 'Hi', text: '…');
      expect(m.to, ['a@x.com']);
    });

    test('to accepts an Iterable<String>', () {
      final m = Message(to: ['a@x.com', 'b@x.com'], subject: 'Hi', text: '…');
      expect(m.to, ['a@x.com', 'b@x.com']);
    });

    test('cc / bcc normalize the same way; default empty', () {
      final m = Message(to: 'a@x.com', cc: 'c@x.com', subject: 'Hi', text: '…');
      expect(m.cc, ['c@x.com']);
      expect(m.bcc, isEmpty);
    });
  });

  group('Attachment', () {
    test('file infers the base name when no filename given', () {
      final a = Attachment.file('/tmp/sub/report.pdf');
      expect(a.filename, 'report.pdf');
      expect(a.path, '/tmp/sub/report.pdf');
    });

    test('bytes and string carry their content', () {
      final b = Attachment.bytes('logo.png', [1, 2, 3], contentType: 'image/png');
      expect(b.bytes, [1, 2, 3]);
      expect(b.contentType, 'image/png');

      final s = Attachment.string('hello.txt', 'hi');
      expect(s.content, 'hi');
    });
  });

  group('Mailer + MemoryTransport', () {
    test('send records the message and resolves the default from', () async {
      final box = MemoryTransport();
      final mailer = Mailer(from: 'no-reply@app.com', transport: box);

      await mailer.send(Message(to: 'user@x.com', subject: 'Hi', text: 'hello'));

      expect(box.sent, hasLength(1));
      expect(box.sent.single.from, 'no-reply@app.com');
      expect(box.sent.single.message.subject, 'Hi');
      expect(box.sent.single.message.to, ['user@x.com']);
    });

    test('per-message from overrides the mailer default', () async {
      final box = MemoryTransport();
      final mailer = Mailer(from: 'default@app.com', transport: box);

      await mailer.send(Message(
        to: 'user@x.com',
        from: 'billing@app.com',
        subject: 'Invoice',
        text: '…',
      ));

      expect(box.sent.single.from, 'billing@app.com');
    });

    test('rejects a message with no recipients', () async {
      final mailer = Mailer(from: 'a@b.com', transport: MemoryTransport());
      expect(
        () => mailer.send(Message(to: <String>[], subject: 'x', text: 'y')),
        throwsArgumentError,
      );
    });

    test('rejects a message with no body', () async {
      final mailer = Mailer(from: 'a@b.com', transport: MemoryTransport());
      expect(
        () => mailer.send(Message(to: 'x@y.com', subject: 'x')),
        throwsArgumentError,
      );
    });

    test('a body-less message with an attachment is allowed', () async {
      final box = MemoryTransport();
      final mailer = Mailer(from: 'a@b.com', transport: box);
      await mailer.send(Message(
        to: 'x@y.com',
        subject: 'file',
        attachments: [Attachment.string('a.txt', 'data')],
      ));
      expect(box.sent, hasLength(1));
    });

    test('clear() empties the recorded messages', () async {
      final box = MemoryTransport();
      final mailer = Mailer(from: 'a@b.com', transport: box);
      await mailer.send(Message(to: 'x@y.com', subject: 'a', text: 'b'));
      box.clear();
      expect(box.sent, isEmpty);
    });
  });

  group('ConsoleTransport', () {
    test('renders a summary to the output sink', () async {
      final lines = <String>[];
      final mailer = Mailer(
        from: 'a@b.com',
        transport: ConsoleTransport(output: lines.add),
      );

      await mailer.send(Message(
        to: 'x@y.com',
        cc: 'c@y.com',
        subject: 'Subject here',
        text: 'body text',
        attachments: [Attachment.string('a.txt', 'x')],
      ));

      final out = lines.join('\n');
      expect(out, contains('From:    a@b.com'));
      expect(out, contains('To:      x@y.com'));
      expect(out, contains('Cc:      c@y.com'));
      expect(out, contains('Subject: Subject here'));
      expect(out, contains('Attachments: a.txt'));
      expect(out, contains('body text'));
    });
  });
}
