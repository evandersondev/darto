# example_response_helpers

What it demonstrates: Every built-in response helper method on Context.

## Features
- `c.json`, `c.text`, `c.html` — typed response bodies
- `c.ok`, `c.created`, `c.noContent` — 2xx helpers
- `c.badRequest`, `c.unauthorized`, `c.forbidden`, `c.notFound`, `c.conflict`, `c.internalError` — error helpers
- `c.status(code).json(...)` — custom status code
- `c.redirect(url)` — redirect response

## Run
```bash
dart run bin/main.dart
```
