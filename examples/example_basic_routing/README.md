# example_basic_routing

What it demonstrates: Core routing — GET/POST, route params, and query strings.

## Features
- `GET /` — simple response
- `GET /users/:id` — route parameter via `c.param` / `c.paramInt`
- `GET /search?q=...&page=...` — query strings via `c.query` / `c.queryInt`
- `POST /users` — reading JSON body via `c.body()`

## Run
```bash
dart run bin/main.dart
```
