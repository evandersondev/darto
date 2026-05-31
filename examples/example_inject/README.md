# example_inject

Typed dependency injection with [`darto_inject`](../../darto_inject/).

## What it shows
- **App-scope** provider (`userServiceProvider`) — one instance shared by every request.
- **Request-scope** provider (`requestIdProvider`) — rebuilt per request, reading the current `Context` via `contextProvider`.
- `Di(...).warmup()` + `di.middleware()` wiring, and `c.read(provider)` inside handlers.

## Run
```bash
dart run bin/main.dart
curl localhost:3000/users
curl localhost:3000/users/1
curl -H 'X-Request-Id: abc-123' localhost:3000/whoami
```

## Also worth trying
Group providers + routes into a `Feature` and mount it once:

```dart
final usersFeature = Feature(
  providers: [userServiceProvider],
  routes: (r) => r.get('/users', [], (c) => c.ok(c.read(userServiceProvider).list())),
);
app.install('/api', usersFeature);
```

In tests, swap a provider with `di.override(userServiceProvider, (di) => FakeUserService())`.
