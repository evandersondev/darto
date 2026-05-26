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

<br/>

---

<br/>

### Support 💖

If you find Darto useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the package and make it even better!

<br/>
