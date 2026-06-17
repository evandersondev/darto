---
name: darto-write-middleware
description: Write and register middleware in a Darto (Dart) app — the Middleware factory pattern, global/path-scoped/route-level registration, short-circuiting, per-request state, and global error/404 handlers. Use when adding cross-cutting behavior (auth, logging, CORS, timing) or configuring app.onError / app.notFound in a project that uses the darto package.
---

# Write middleware in Darto

A middleware receives the same `Context` as handlers, plus a `Next` callback.
Call `await next()` to continue the pipeline; **return without calling `next()`
to short-circuit** (reject the request).

```dart
typedef Middleware = FutureOr<void> Function(Context c, Next next);
typedef Next       = Future<void>   Function();
```

## Writing one (factory pattern)

Define a function that **returns** a `Middleware` closure. This lets the
middleware take configuration:

```dart
Middleware timer() => (Context c, Next next) async {
  final sw = Stopwatch()..start();
  await next();                       // run downstream
  print('${c.req.method} ${c.req.path}  ${sw.elapsedMilliseconds}ms');
};
```

### Short-circuit (reject before the handler)

Set a response and `return` without calling `next()`:

```dart
Middleware requireAdmin() => (Context c, Next next) async {
  if (c.user?['role'] != 'admin') {
    c.forbidden({'error': 'Admins only'});
    return;                            // pipeline stops here
  }
  await next();
};
```

### Sharing data with handlers

Use per-request state, set before `next()` and read downstream:

```dart
Middleware loadUser() => (Context c, Next next) async {
  c.set('userId', '42');               // or: c.user = {...}
  await next();
};
// in a handler: final id = c.get<String>('userId');
```

## Registering middleware

Pick the narrowest scope that fits:

```dart
// Global — runs on every request. Call use() once per middleware.
app.use(logger());
app.use(timer());

// Path-scoped — runs on matching paths. Call mount() once per middleware.
app.mount('/api/*', cors());
app.mount('/api/*', jwtMiddleware);

// Route-level — only this route (the required middleware list):
app.get('/admin', [requireAdmin()], handler);
app.post('/upload', [bodyLimit(maxSize: 5 * 1024 * 1024)], handler);
```

Order matters: middleware runs in registration order, outermost first.

## Built-in middleware

Darto ships many; each lives in its own sub-library, imported individually:

```dart
import 'package:darto/logger.dart';     app.use(logger());
import 'package:darto/cors.dart';        app.mount('/api/*', cors(origin: '*'));
import 'package:darto/jwt.dart';         // JWT auth
import 'package:darto/etag.dart';        app.use(etag());
import 'package:darto/request_id.dart';  app.use(requestId());   // requestIdOf(c)
import 'package:darto/rate_limit.dart';
import 'package:darto/csrf.dart';
import 'package:darto/compress.dart';
import 'package:darto/body_limit.dart';
```

(See the `darto/lib/` directory for the full list.)

## Global error & 404 handlers

These are **not** Express-style error middleware — register them on the app and
they receive a `Context`:

```dart
app.onError((DartoError err, Context c) {
  // err.cause (original object), err.stackTrace, err.message
  return c.internalError({'error': err.message});
});

app.notFound((Context c) {
  return c.notFound({'error': 'Route not found: ${c.req.path}'});
});
```

Throwing inside any handler/middleware routes to `onError`.

## Complete example

```dart
import 'package:darto/darto.dart';
import 'package:darto/logger.dart';

Middleware requireAdmin() => (Context c, Next next) async {
  if (c.user?['role'] != 'admin') { c.forbidden(); return; }
  await next();
};

void main() {
  final app = Darto();

  app.use(logger());                                   // global
  app.mount('/admin/*', (c, next) async {              // path-scoped auth gate
    c.user = {'role': 'admin'};                        // (demo) load real user here
    await next();
  });

  app.get('/admin/stats', [requireAdmin()], (c) => c.ok({'visits': 10}));

  app.onError((err, c) => c.internalError({'error': err.message}));
  app.notFound((c) => c.notFound({'error': 'not found'}));

  app.listen(3000);
}
```

## Common mistakes

- ❌ Forgetting `await next()` when the request should continue — the pipeline stalls.
- ❌ Calling `next()` *and then* also setting a response to reject — pick one.
- ❌ Express error middleware `(err, req, res, next)` — use `app.onError((DartoError err, Context c) {...})`.
