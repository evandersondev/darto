# example_context_usage

What it demonstrates: Full Context API — c.set/get, params, query, body, headers.

## Features
- `c.set` / `c.get` for passing data between middleware and handler
- `c.param` / `c.paramInt` for route parameters
- `c.query` / `c.queryInt` for query strings
- `c.body()` for JSON request bodies
- `c.header()`, `c.method`, `c.path`, `c.ip`

## Run
```bash
dart run bin/main.dart
```
