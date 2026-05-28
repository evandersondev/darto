## 1.0.0

- Initial release.
- `Mailer` — a default `from` + a pluggable `MailTransport`; validates
  recipients/body and delegates each send.
- `Message` — `to` / `cc` / `bcc` (String or Iterable), `replyTo`, `subject`,
  `text`, `html`, `attachments` and raw `headers`, with an optional
  per-message `from`.
- `Attachment.file` / `Attachment.bytes` / `Attachment.string`.
- `SmtpTransport` — production transport over the pure-Dart `mailer` package
  with `SmtpSecurity.none / ssl / starttls`.
- `ConsoleTransport` (dev — prints a summary) and `MemoryTransport` (tests —
  records sends into a list).
