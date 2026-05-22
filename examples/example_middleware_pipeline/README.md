# example_middleware_pipeline

What it demonstrates: Middleware execution order with before/after `next()` calls.

## Features
- Three chained middlewares: timer, requestId, logRequest
- Print statements show before/after `next()` ordering
- Per-route middleware list via third argument to `app.get`

## Run
```bash
dart run bin/main.dart
```
