# AGENTS.md

Guidance for AI coding agents working in this repository. For end-user API docs
see [`darto/REFERENCE.md`](./darto/REFERENCE.md) and https://darto-docs.vercel.app/.

For **task-scoped procedures** (add a route, validate a request, write
middleware, scaffold a project), load the matching Claude Skill in
[`skills/`](./skills/). Machine-readable docs for the site live at
[`/llms.txt`](https://darto-docs.vercel.app/llms.txt).

## Overview

Darto is a minimal, type-safe web framework for **pure Dart** (no Flutter, no
Node/JS). It is *inspired by* Express but its actual programming model is
**Hono-style**: everything flows through a single `Context` object. This repo is
a **monorepo** — the core `darto` package plus an ecosystem of plugins
(`darto_*`) and runnable `examples/`.

## The #1 thing to get right: Context, not (req, res, next)

Darto's lineage is Express, but as of v1.x the API is **not** Express. Do **not**
write `(Request req, Response res, Next next)` handlers, `res.send()`, or
Express-style error middleware — that is the *old* API and will not compile.

A handler takes a single `Context c` and **returns** a `Response`:

```dart
import 'package:darto/darto.dart';

void main() {
  final app = Darto();

  app.get('/users/:id', [], (Context c) {
    final id = c.req.param('id');   // read request via c.req
    return c.ok({'id': id});        // RETURN a response helper
  });

  app.listen(3000);
}
```

The three typedefs that define the whole framework:

```dart
typedef Handler    = FutureOr<Response>? Function(Context c);
typedef Middleware = FutureOr<void>      Function(Context c, Next next);
typedef Next       = Future<void>        Function();
```

## Conventions an agent won't infer

- **Middleware list is a required positional arg** on every verb method. Pass
  `[]` when there is no route-level middleware:
  `app.get(path, [middlewares], handler)`. Never omit it.
- **Return responses, don't "send" them.** Use the helpers and `return` them:
  `c.ok`, `c.created`, `c.noContent`, `c.badRequest`, `c.unauthorized`,
  `c.forbidden`, `c.notFound`, `c.conflict`, `c.internalError`, or typed
  `c.json(data, [status])`, `c.text`, `c.html`, `c.redirect`, `c.binary`,
  `await c.file(...)`, `await c.download(...)`. Chain status with
  `c.status(206).json(...)`.
- **`c.body(...)` is a *response* helper** (raw body), not a request reader.
- **Read the request through `c.req`**: `c.req.param('id')` / `paramInt`,
  `c.req.query('page')` / `queryInt` / `queryBool`, `c.req.header('...')`,
  and the body via `await c.req.json()` (or `c.req.json<T>(T.fromJson)`),
  `c.req.text()`, `c.req.blob()`.
- **Per-request state:** `c.set('k', v)` / `c.get<T>('k')`; auth shortcut
  `c.user`.
- **Writing middleware:** factory returning a closure; `await next()` to
  continue, `return` (without `next`) to short-circuit:
  ```dart
  Middleware requireAdmin() => (Context c, Next next) async {
    if (c.user?['role'] != 'admin') { c.forbidden(); return; }
    await next();
  };
  ```
- **Error & 404 handling** use Context too — not Express error middleware:
  ```dart
  app.onError((DartoError err, Context c) => c.internalError({'error': err.message}));
  app.notFound((Context c) => c.notFound({'error': 'not found'}));
  ```
- **Validation** is `zValidator` from `darto_validator` (Zod-style via `zard`),
  used as route middleware; read the result with
  `c.req.valid<Map<String, dynamic>>('json' | 'query' | 'param')`.
- **There is no built-in ORM/database layer.** Don't introduce or assume one
  (e.g. "Dartonic") — persistence is left to the application.

## Imports

- Core API: `import 'package:darto/darto.dart';`
- Built-in middlewares live in their own sub-libraries, imported individually:
  `package:darto/logger.dart`, `package:darto/cors.dart`, `package:darto/jwt.dart`,
  `package:darto/etag.dart`, `package:darto/request_id.dart`,
  `package:darto/cookie.dart`, `package:darto/rate_limit.dart`, etc.
  (see [`darto/lib/`](./darto/lib/)).
- Ecosystem features come from their own package, e.g.
  `package:darto_validator/darto_validator.dart`,
  `package:darto_ws/darto_ws.dart`, `package:darto_view/darto_view.dart`.

## Repository layout

- `darto/` — core framework. Public API surface is the sub-libraries in
  `darto/lib/`; implementation is in `darto/lib/src/{core,helpers,middlewares}`.
- `darto_*/` — independent plugin packages, each with its own `pubspec.yaml`
  and tests. `darto_inject` was formerly `darto_di`.
- `examples/example_*/` — small runnable apps; the best reference for idiomatic
  usage of each feature.
- `darto-docs/` — the documentation website (Vite + React + TanStack Router,
  package manager **bun**). Doc content is data-driven in
  `darto-docs/src/lib/docs-content.ts`; `llms.txt` / `llms-full.txt` are
  generated from it (`bun run docs:llms`).

## Build, run, test

There is **no melos / workspace root** — each package is standalone. Operate
inside the relevant package directory:

```sh
dart pub get          # install deps (run per package)
dart test             # run that package's tests
dart analyze          # static analysis
dart format .         # format (enforced style)
dart run              # run an example/app from its bin/
```

For the docs site, work inside `darto-docs/` and use bun: `bun i`, `bun run dev`,
`bun run build` (the build regenerates `llms.txt`).

The CLI (`darto_cli`) scaffolds and runs apps: `dart pub global activate darto_cli`,
then `darto create`, `darto dev` (hot reload), `darto build`, `darto start`.

## Code style

- Idiomatic Dart, formatted with `dart format` (no custom column overrides).
- Lints: `package:lints/recommended` (see `darto/analysis_options.yaml`).
  Keep `dart analyze` clean.
- File names are `snake_case.dart`; types `UpperCamelCase`; members
  `lowerCamelCase`.
- Match the surrounding file's style; comments are sparse and explain *why*.
- SDK constraint is `>=3.0.0 <4.0.0` — Dart 3 features are fine.

## Tests

- Use `package:test`. Core tests boot a real server via the shared harness in
  [`darto/test/support/harness.dart`](./darto/test/support/harness.dart)
  (`withServer((app) {...}, (port) async {...})`).
- The `darto_test` package offers an ergonomic, supertest-style client for
  asserting against an app booted on an ephemeral port — prefer it for
  app-level integration tests.
- Add or update tests in the same package as the code you change.

## Don't touch / be careful

- Don't reintroduce the legacy Express-style API anywhere.
- Don't edit generated files: `darto-docs/src/routeTree.gen.ts` and the
  generated `darto-docs/public/llms.txt` / `llms-full.txt` (regenerate via
  `bun run docs:llms` instead).
- Don't hand-edit `pubspec.lock`; change `pubspec.yaml` and run `dart pub get`.
- Keep each package's public API and CHANGELOG/version in sync when changing
  behavior — these are published to pub.dev.
- `node_modules/`, `dist/`, and `.dart_tool/` are build artifacts — never commit
  or edit them.
