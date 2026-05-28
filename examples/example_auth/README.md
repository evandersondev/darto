# example_auth

Password hashing + session auth with [`darto_auth`](../../darto_auth/).

> For the **core JWT** middleware (stateless tokens), see [`example_auth_jwt`](../example_auth_jwt/).

## What it shows
- `hashPassword` / `verifyPassword` — PBKDF2, constant-time verify, no plaintext.
- Session login via `signIn` / `signOut`, protected routes with `authGuard()` and `authUser(c)`.
- A commented-out **OAuth 2.0 / OIDC** ("Sign in with Google") block — fill in credentials to enable.

## Run
```bash
dart run bin/main.dart

# Login as the seeded user, keeping the session cookie:
curl -c jar.txt -X POST localhost:3000/login \
  -H 'Content-Type: application/json' -d '{"email":"alice@example.com","password":"s3cret"}'

# Use the cookie to hit a protected route:
curl -b jar.txt localhost:3000/me

# Without the cookie → 401:
curl -i localhost:3000/me
```
