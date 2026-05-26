# example_auth_jwt

What it demonstrates: JWT authentication and role-based access control with darto_auth.

## Features
- `POST /login` — validates credentials and issues a signed JWT
- `GET /me` — protected by `jwt()` middleware, reads `c.user`
- `GET /admin` — protected by `jwt()` + `requireRoles(['admin'])`
- `JwtUtils.sign` / `JwtUtils.verify` — pure-Dart HS256 JWT

## Test users
| email | password | roles |
|-------|----------|-------|
| alice@example.com | pass123 | user |
| admin@example.com | admin123 | user, admin |

## Run
```bash
dart run bin/main.dart
```

<br/>

---

<br/>

### Support 💖

If you find Darto useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the package and make it even better!

<br/>
