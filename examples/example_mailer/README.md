# example_mailer

Sending email with [`darto_mailer`](../../darto_mailer/).

## What it shows
- A `/signup` route that sends a welcome email.
- `ConsoleTransport` (prints instead of sending) so it runs with no SMTP server.
- How to swap in `SmtpTransport` for real delivery (commented).

## Run
```bash
dart run bin/main.dart
curl -X POST localhost:3000/signup \
  -H 'Content-Type: application/json' -d '{"email":"user@example.com"}'
# → the rendered email is printed to the server console
```

## Real delivery
Replace the transport with SMTP:

```dart
transport: SmtpTransport(
  host: 'smtp.example.com', port: 587,
  username: env.smtpUser, password: env.smtpPass,
  security: SmtpSecurity.starttls,
),
```

To test SMTP locally without a provider, run [Mailpit](https://github.com/axllent/mailpit)
and use `SmtpSecurity.none` on its port.
