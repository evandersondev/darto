<br>

<p align="center">
  <img src="https://raw.githubusercontent.com/evandersondev/darto/main/imgs/darto-logo.png" alt="Darto Logo" width="200"/>
</p>

<br>

# darto_mailer

Email sending for the [Darto](https://pub.dev/packages/darto) ecosystem — a
small `Mailer` API with an **SMTP** transport, plus **console** and **memory**
transports for development and tests.

## Install

```yaml
dependencies:
  darto_mailer: ^1.0.0
```

## Quick start

```dart
import 'package:darto_mailer/darto_mailer.dart';

final mailer = Mailer(
  from: 'no-reply@example.com',
  transport: SmtpTransport(
    host: 'smtp.example.com',
    port: 587,
    username: env.smtpUser,
    password: env.smtpPass,
    security: SmtpSecurity.starttls, // none | ssl | starttls
  ),
);

await mailer.send(Message(
  to: 'user@example.com',
  subject: 'Welcome!',
  text: 'Hello, welcome aboard.',
  html: '<h1>Hello!</h1><p>Welcome aboard.</p>',
));
```

## Recipients, cc/bcc and attachments

```dart
await mailer.send(Message(
  to: ['a@x.com', 'b@x.com'],
  cc: 'manager@x.com',
  bcc: 'audit@x.com',
  replyTo: 'support@x.com',
  subject: 'Monthly report',
  html: '<p>See attached.</p>',
  attachments: [
    Attachment.file('report.pdf'),
    Attachment.bytes('logo.png', bytes, contentType: 'image/png'),
    Attachment.string('notes.txt', 'plain notes'),
  ],
));
```

`to` / `cc` / `bcc` accept either a single `String` or an `Iterable<String>`.

## Dev & test transports (no network)

```dart
// Dev — prints a summary instead of sending
final mailer = Mailer(from: '…', transport: ConsoleTransport());

// Tests — capture messages and assert on them
final box = MemoryTransport();
final mailer = Mailer(from: 'a@b.com', transport: box);
await mailer.send(Message(to: 'x@y.com', subject: 'Hi', text: '…'));
expect(box.sent.single.message.subject, 'Hi');
```

## With `darto_inject`

```dart
final mailerProvider = Provider<Mailer>(
  (di) => Mailer(
    from: 'no-reply@app.com',
    transport: SmtpTransport(host: env.smtpHost, username: …, password: …),
  ),
  onDispose: (m) => m.close(),
);

app.post('/forgot', [], (c) async {
  final mailer = c.read(mailerProvider);
  await mailer.send(Message(to: email, subject: 'Reset', html: resetHtml));
  return c.noContent();
});
```

## Templates

`darto_mailer` doesn't ship a template engine — pass `html` / `text` you've
already rendered.  Combine it with **[darto_view](https://pub.dev/packages/darto_view)**
(Mustache / Jinja) to render the body, then drop the result into a `Message`.

## API

| Type | Purpose |
|---|---|
| `Mailer({from, transport})` | Sends messages; injects the default `from` |
| `Message({to, cc, bcc, replyTo, subject, text, html, attachments, headers, from})` | An email |
| `Attachment.file / .bytes / .string` | Attachment constructors |
| `MailTransport` | Interface — `send(message, from)` + `close()` |
| `SmtpTransport({host, port, username, password, security})` | SMTP delivery (pure-Dart) |
| `SmtpSecurity` | `none` / `ssl` / `starttls` |
| `ConsoleTransport` / `MemoryTransport` | Dev / test transports |

## Testing the SMTP transport

The SMTP suite is tagged `smtp` and boots a disposable
[Mailpit](https://github.com/axllent/mailpit) container (a fake SMTP server
with an HTTP API):

```sh
dart test --tags smtp     # only the SMTP integration suite
dart test                 # everything (incl. SMTP if Docker is up)
```

`docker` must be on the PATH and able to pull (or already have) the
`axllent/mailpit` image.

<br/>

---

<br/>

### Support 💖

If you find Darto Mailer useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟
