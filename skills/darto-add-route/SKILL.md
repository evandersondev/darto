---
name: darto-add-route
description: Add or modify HTTP endpoints in a Darto (Dart) web app — verbs, path/query params, request-body reading, route groups, and Context response helpers. Use when building or changing API routes in a project that depends on the `darto` package (import 'package:darto/darto.dart'). Not for Express/Node — Darto handlers take a single Context, not (req, res, next).
---

# Add a route to a Darto app

Darto is a pure-Dart web framework with a **Hono-style single `Context`** model.
A handler receives one `Context c` and **returns** a `Response`. It is *not*
Express: there is no `(req, res, next)`, no `res.send()`.

## The contract

```dart
typedef Handler    = FutureOr<Response>? Function(Context c);
typedef Middleware = FutureOr<void>      Function(Context c, Next next);
typedef Next       = Future<void>        Function();
```

## Procedure

1. **Import the core library** (only this for routing):
   ```dart
   import 'package:darto/darto.dart';
   ```
2. **Register the route.** Every verb method takes three arguments:
   `app.verb(path, [middlewares], handler)`. The middleware list is
   **required** — pass `[]` when there is none.
   ```dart
   app.get('/users/:id', [], (Context c) {
     final id = c.req.param('id');
     return c.ok({'id': id});
   });
   ```
   Verbs: `get post put patch delete head options all`. For custom or multiple
   verbs/paths: `app.on(['GET','POST'], ['/a','/b'], [], handler)`.
3. **Read the request through `c.req`** (never a separate request arg):
   - Params: `c.req.param('id')`, `c.req.paramInt('id')`, `c.req.paramDouble('id')`
   - Query: `c.req.query('page')`, `c.req.queryInt`, `c.req.queryBool` (`true/1/yes/on`)
   - Headers: `c.req.header('authorization')`
   - Body: `await c.req.json()` → `Map`, or typed `await c.req.json<User>(User.fromJson)`;
     also `c.req.text()`, `c.req.blob()` (`Uint8List`).
   - URL info: `c.req.method`, `c.req.path`, `c.req.url`, `c.req.ip`
4. **Return a response** — always `return` a helper, don't "send":
   - Status helpers: `c.ok` (200), `c.created` (201), `c.noContent` (204),
     `c.badRequest` (400), `c.unauthorized` (401), `c.forbidden` (403),
     `c.notFound` (404), `c.conflict` (409), `c.internalError` (500).
   - Typed: `c.json(data, [status])`, `c.text(str, [status])`, `c.html(str, [status])`.
   - Custom: `c.status(206).json(data)`. Headers: `c.header('X-Id', v)`.
   - Files/redirect: `c.binary(bytes, contentType: ...)`, `await c.file(path)`,
     `await c.download(path, filename: ...)`, `c.redirect('/path', [301])`.
5. **Listen** (once, at the bottom of `main`): `app.listen(3000);`

## Path patterns

```dart
app.get('/posts/:slug?', [], handler);        // optional param
app.get('/items/:id(\\d+)', [], handler);      // regex constraint
app.get('/files/*path', [], (c) => c.text(c.req.param('path') ?? '')); // named wildcard
app.get('/assets/*', [], handler);             // unnamed wildcard
```

## Grouping related routes

Prefer groups/routers over repeating prefixes:

```dart
// Fluent group on a path
app.route('/users')
  .get([], listUsers)
  .post([auth()], createUser);

// Prefix group
final api = app.group('/api');
api.get('/status', [], (c) => c.ok({'ok': true}));

// Standalone, reusable Router
Router userRouter() {
  final r = Router();
  r.get('/', [], listUsers);
  r.get('/:id', [], getUser);
  return r;
}
```

## Complete example

```dart
import 'package:darto/darto.dart';

void main() {
  final app = Darto();

  final api = app.group('/api');

  api.get('/users/:id', [], (Context c) {
    final id = c.req.paramInt('id');
    if (id == null) return c.badRequest({'error': 'invalid id'});
    return c.ok({'id': id, 'name': 'Alice'});
  });

  api.post('/users', [], (Context c) async {
    final body = await c.req.json();
    return c.created({'user': body});
  });

  app.listen(3000, () => print('http://localhost:3000'));
}
```

## Common mistakes to avoid

- ❌ `(Request req, Response res)` / `res.send()` / `res.json()` — legacy API, won't compile.
- ❌ Omitting the middleware list: `app.get('/x', handler)` — pass `[]`.
- ❌ Forgetting to `return` the response from the handler.
- ❌ Reading the body via `c.body()` — that is a **response** helper; use `c.req.json()`.

For validation use the `darto-validate-request` skill; for middleware use
`darto-write-middleware`.
