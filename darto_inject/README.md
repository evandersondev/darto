<br>

<p align="center">
  <img src="https://raw.githubusercontent.com/evandersondev/darto/main/imgs/darto-logo.png" alt="Darto Logo" width="200"/>
</p>

<br>

# darto_inject

Typed **dependency injection** for the [Darto](https://pub.dev/packages/darto)
web framework — `Provider<T>` factories with **app** and **request** scopes,
lifecycle hooks, test overrides and a built-in `contextProvider`.

No `build_runner`, no decorators, no reflection.  Inspired by Riverpod, fitted
to the HonoJS-style `Context` Darto already gives you.

## Install

```yaml
dependencies:
  darto_inject: ^1.0.0
```

## Quick start

```dart
import 'package:darto/darto.dart';
import 'package:darto_inject/darto_inject.dart';

// 1. Declare providers — pure values, no annotations.
final envProvider = Provider<Env>((di) => Env.fromFile('.env'));
final dbProvider = Provider<Db>(
  (di) => Db.connect(di.read(envProvider).dbUrl),
  onDispose: (db) => db.close(),
);
final userServiceProvider = Provider<UserService>(
  (di) => UserService(di.read(dbProvider)),
);

void main() async {
  // 2. Build the container and warm up app-scope singletons.
  final di = Di(providers: [envProvider, dbProvider, userServiceProvider]);
  await di.warmup();

  // 3. Install the middleware — opens a request scope per request.
  final app = Darto()..use(di.middleware());

  app.get('/users', [], (c) {
    final svc = c.read(userServiceProvider);
    return c.ok(svc.list());
  });

  app.listen(3000);
  await di.dispose(); // runs every onDispose in reverse-creation order
}
```

## Providers

```dart
// app-scope (default): built once, lives until di.dispose()
final dbProvider = Provider<Db>((di) => Db.connect(...));

// request-scope: a fresh value per request, disposed when the response is sent
final requestLogger = Provider<Logger>(
  (di) => di.read(loggerProvider).child({
    'reqId': requestIdOf(di.read(contextProvider)),
  }),
  scope: Scope.request,
);

// async: factory awaits something
final cache = AsyncProvider<Cache>(
  (di) async => RedisCache.connect(await di.read(envProvider).redisUrl),
);
```

Inside a handler:

```dart
app.get('/me', [], (c) async {
  final db    = c.read(dbProvider);                  // sync
  final cache = await c.readAsync(cache);            // async
  final log   = c.read(requestLogger);
  ...
});
```

## `contextProvider` — built-in

Read the current `Context` from any **request-scope** factory.  Use it to
derive per-request things without leaking the Context into your services:

```dart
final currentUserProvider = AsyncProvider<User?>(
  (di) async {
    final c = di.read(contextProvider);
    final token = c.req.header('authorization')?.replaceFirst('Bearer ', '');
    return token == null ? null : await di.read(userServiceProvider).fromToken(token);
  },
  scope: Scope.request,
);
```

Reading `contextProvider` from app scope throws — there is no Context to bind
to before a request exists.

## Test overrides

```dart
test('GET /me uses the fake user service', () async {
  final di = Di(providers: [userServiceProvider])
    ..override(userServiceProvider, (di) => FakeUserService());

  final app = buildApp(di);
  final client = await TestClient.create(app);
  final res = await client.get('/me');
  expect(res.statusCode, 200);
  await client.close();
});
```

`override` replaces the factory for the lifetime of the container — every
read (and every child request scope) sees the new factory.

## Features

Group a set of providers with the routes that use them:

```dart
final userFeature = Feature(
  providers: [userServiceProvider, userRepoProvider],
  routes: (r) {
    r.get('/users', [], listUsers);
    r.post('/users', [authGuard()], createUser);
  },
);

final (sync, async) = collectProviders([userFeature, billingFeature]);
final di = Di(providers: sync, asyncProviders: async);

final app = Darto()
  ..use(di.middleware())
  ..install('/api', userFeature)
  ..install('/api', billingFeature);
```

A `Feature` is just `(providers, routes)`.  It doesn't extend anything.

## Lifecycle

- **`onDispose`** runs on every cached instance, in **reverse creation order**,
  so a service can still use its dependencies during cleanup.
- **App scope**: `di.dispose()` is the trigger — call it after `app.stop()`.
- **Request scope**: disposal is automatic — happens right after the
  response is written, even if the handler threw.

## API

| Type | Purpose |
|---|---|
| `Provider<T>(factory, {scope, onDispose, name})` | Synchronous typed factory |
| `AsyncProvider<T>(factory, {scope, onDispose, name})` | Asynchronous typed factory |
| `Scope.app` / `Scope.request` | Lifetime of the cached instance |
| `Di({providers, asyncProviders})` | Container — holds factories, caches, overrides |
| `Di.warmup()` | Eagerly builds every app-scope provider |
| `Di.dispose()` | Runs every app-scope `onDispose` |
| `Di.override(p, factory)` / `Di.overrideAsync(p, factory)` | Replace a factory (tests) |
| `Di.middleware()` | Darto `Middleware` that opens a request scope per request |
| `contextProvider` | Built-in `Provider<Context>` for request-scope factories |
| `c.read(p)` / `c.readAsync(p)` | Resolve a provider in the current request |
| `Feature({providers, asyncProviders, routes})` | A providers + routes bundle |
| `app.install([prefix], feature)` | Mount a feature, optionally under a prefix |
| `collectProviders(features)` | Flatten features into `(sync, async)` provider lists |

<br/>

---

<br/>

### Support 💖

If you find Darto DI useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟
