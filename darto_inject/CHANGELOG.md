## 1.0.1

- Fix a runtime type error when disposing a provider read through a
  `dynamic`-narrowed handle (e.g. during `di.warmup()` / `readAsync<dynamic>`):
  the disposer is now bound with the provider's reified type via
  `disposerFor(value)`, avoiding a covariant field-read crash.

## 1.0.0

- Initial release.
- `Provider<T>` (sync) and `AsyncProvider<T>` (async) — typed factories with
  app- or request-scope.
- `Di` container: caches instances per scope, supports `override(...)` for
  tests and runs `onDispose` callbacks in reverse-creation order.
- Context extension `c.read(provider)` / `c.readAsync(provider)` and built-in
  `contextProvider` exposing the current `Context` inside request-scope
  factories.
- `di(container).middleware()` — registers a Darto middleware that opens a
  request scope per request and disposes it on completion.
- `Feature(providers, routes)` + `app.install([prefix], feature)` — group a
  set of providers with their routes; install once.
