# example_full_integration

What it demonstrates: A complete mini-app combining logging, JWT auth, and validation.

## Features
- Global `logger()` middleware logs every request
- `POST /auth/login` — returns a signed JWT token
- `GET /api/profile` — JWT-protected, returns `c.user`
- `POST /api/items` — JWT-protected + validated body (name + price)
- Route groups via `app.route()` and path-scoped `app.use('/api', jwt(...))`

## Run
```bash
dart run bin/main.dart
```
