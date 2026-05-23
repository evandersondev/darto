# Darto

**Minimal, fast and type-safe web framework for Dart — inspired by Hono.**

Everything flows through a single concept: **Context**.

---

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
- [Application](#application)
- [Routing](#routing)
- [Context API](#context-api)
- [Render / Layouts](#render--layouts)
- [View Engine](#view-engine)
- [Request (`c.req`)](#request-creq)
- [Response Factories](#response-factories)
- [Middleware](#middleware)
- [Built-in Middlewares](#built-in-middlewares)
- [Validation](#validation)
- [File Upload](#file-upload)
- [File Download](#file-download)
- [WebSocket](#websocket)
- [Helpers](#helpers)
  - [Validator](#validator)
- [HTTP Status Codes](#http-status-codes)
- [Error Handling](#error-handling)
- [CLI](#cli)
- [Examples](#examples)

---

## Installation

```yaml
dependencies:
  darto: ^1.0.0
```

---

## Quick Start

```dart
import 'package:darto/darto.dart';

void main() async {
  final app = Darto();

  app.get('/users/:id', [], (Context c) {
    final id = c.req.param('id');
    return c.ok({'id': id});
  });

  await app.listen(3000, () => print('Listening on http://localhost:3000'));
}
```

---

## Core Concepts

Three typedefs are all you need to understand:

```dart
typedef Handler    = FutureOr<Response>? Function(Context c);
typedef Middleware = FutureOr<void>      Function(Context c, Next next);
typedef Next       = Future<void>        Function();
```

- A **handler** receives a `Context` and returns a `Response`.
- A **middleware** receives a `Context` and a `Next` callback.  
  Call `await next()` to pass control to the next middleware or the handler.  
  Return without calling `next()` to short-circuit the pipeline.

---

## Application

### Creating the app

```dart
final app = Darto();             // default (non-strict trailing slash)
final app = Darto(strict: true); // /users ≠ /users/
```

### Global base path

Prepend a prefix to every route registered on the instance:

```dart
final app = Darto().basePath('/v1');

app.get('/users', [], handler); // registered as /v1/users
```

### Starting and stopping

```dart
await app.listen(3000);
await app.listen(3000, () => print('ready'));

await app.stop();

bool running = app.isRunning;
```

### Inspecting routes

```dart
// List<RouteSpec> — {method, path}
final specs = app.routes;

// List of records — {method, path, middlewareCount}
final entries = app.routeEntries;
```

---

## Routing

### HTTP verbs

```dart
app.get(path, middlewares, handler);
app.post(path, middlewares, handler);
app.put(path, middlewares, handler);
app.patch(path, middlewares, handler);
app.delete(path, middlewares, handler);
app.head(path, middlewares, handler);
app.options(path, middlewares, handler);

// All verbs
app.all(path, middlewares, handler);

// Custom / multiple verbs × multiple paths
app.on(['GET', 'POST'], ['/a', '/b'], [], handler);
app.on(['PURGE'], ['/cache'], [], handler);
```

### Route parameters

```dart
// Named param
app.get('/users/:id', [], (c) => c.ok({'id': c.req.param('id')}));

// Optional param
app.get('/posts/:slug?', [], handler);

// Regex constraint
app.get('/items/:id(\\d+)', [], handler);

// Named wildcard
app.get('/files/*path', [], (c) => c.text(c.req.param('path') ?? ''));

// Unnamed wildcard
app.get('/assets/*', [], handler);
```

### Route groups — fluent chaining

```dart
app.route('/users')
  .get([], listUsers)
  .post([auth()], createUser)
  .on(['PUT', 'DELETE'], [], handler);
```

### Route groups — builder callback

```dart
app.route('/users', (r) {
  r.get('/',    [], listUsers);
  r.post('/',   [auth()], createUser);
  r.get('/:id', [], getUser);
  r.delete('/:id', [auth()], deleteUser);
});
```

### Grouped prefix

```dart
final api = app.group('/api');

api.get('/status', [], (c) => c.ok({'ok': true}));
api.get('/users', [jwtMiddleware], listUsers);
```

### Standalone Router

```dart
Router userRouter() {
  final r = Router();
  r.get('/',    [], listUsers);
  r.post('/',   [], createUser);
  r.get('/:id', [], getUser);
  return r;
}

// Attach it via group
final users = app.group('/users');
users.get('/',    listUsers);
users.post('/',   createUser);
users.get('/:id', getUser);
```

### Nested groups

```dart
app.group('/api')
   .group('/v2')
   .get('/ping', (c) => c.text('pong'));
// → GET /api/v2/ping
```

---

## Context API

The `Context` object is the single entry point for everything request/response related.

### Response helpers

```dart
// Success
c.ok([body])           // 200
c.created([body])      // 201
c.noContent()          // 204

// Client errors
c.badRequest([body])   // 400
c.unauthorized([body]) // 401
c.forbidden([body])    // 403
c.notFound([body])     // 404
c.conflict([body])     // 409

// Server errors
c.internalError([body]) // 500

// Typed responses
c.json(data, [status])  // application/json
c.text(str, [status])   // text/plain
c.html(str, [status])   // text/html

// Custom status + body
c.status(206).json(data)
c.status(418).text("I'm a teapot")

// Binary / files
c.binary(bytes, status: 200, contentType: 'image/png')

// Streamed — no full-file buffering, sends Content-Length automatically
await c.file('/path/to/file.pdf')
await c.file('/path/to/image.png', contentType: 'image/png')

// Force-download with Content-Disposition header
await c.download('/path/to/report.csv')
await c.download('/path/to/report.csv', filename: 'export.csv')

// Redirect
c.redirect('/new-path')
c.redirect('/login', 301)
```

### Response headers

```dart
c.header('X-Request-Id', uuid);
```

### Body reading

```dart
// JSON → Map<String, dynamic>
final body = await c.body();

// JSON → typed DTO
final user = await c.body<User>(User.fromJson);

// Raw bytes
final bytes = await c.bodyRaw(); // List<int>
```

### State (per-request storage)

```dart
c.set('userId', '42');
final id = c.get<String>('userId');
```

### Auth shortcut

```dart
c.user = {'id': '42', 'role': 'admin'};
final user = c.user; // Map<String, dynamic>?
```

### Validation result

```dart
// zValidator (recommended) — retrieve with c.valid<T>(target)
final data  = c.valid<Map<String, dynamic>>('json');
final query = c.valid<Map<String, dynamic>>('query');

// Legacy helpers — retrieve with c.validated<T>()
final dto = c.validated<UserDto>();
final dto = c.validated<UserDto>('myKey'); // custom key
```

### Response introspection

```dart
int code = c.statusCode;      // current status (200 if not set)
Response? res = c.response;   // current Response object or null
c.respond(existingResponse);  // set a full Response directly
c.clearResponse();            // reset (used by middleware combiners)
```

### Route metadata

```dart
List<RouteSpec>? routes = c.matchedRoutes;
String? pattern = c.routePath;      // '/posts/:id'
String? prefix  = c.baseRoutePath;  // '/api'   (group prefix pattern)
String? base    = c.basePath;       // '/api'   (resolved with actual values)
```

---

## Render / Layouts

Darto provides a two-step rendering API modelled after Hono's `setRenderer` / `c.render`.

### `setRender` — register a layout

Call `c.setRender(layout)` — usually from a global middleware — to define an HTML layout that wraps every subsequent `c.render(content)` call on that request.

```dart
// Register the layout for all routes
app.use((Context c, Next next) async {
  c.setRender((content, props) => c.html('''
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8">
        <title>${props['title'] ?? 'Darto App'}</title>
      </head>
      <body>
        $content
      </body>
    </html>
  '''));
  await next();
});
```

The `RenderLayout` typedef:

```dart
typedef RenderLayout = FutureOr<Response> Function(
  String content,
  Map<String, dynamic> props,
);
```

### `render` — use the layout in a handler

```dart
app.get('/', (Context c) {
  return c.render('<h1>Welcome</h1>', {'title': 'Home'});
});

app.get('/about', (Context c) {
  return c.render('''
    <h1>About</h1>
    <p>Built with Darto.</p>
  ''', {'title': 'About Us'});
});
```

**Signature:**

```dart
Future<Response> render(String content, [Map<String, dynamic> props = const {}])
```

- When a layout **is** registered: calls `layout(content, props)` and returns its `Response`.
- When **no** layout is registered: returns `c.html(content)` directly.

### Per-route layout override

You can register different layouts for different path groups:

```dart
// Default layout (all routes)
app.use((Context c, Next next) async {
  c.setRender((html, props) => c.html('<html><body>$html</body></html>'));
  await next();
});

// Admin layout (overrides for /admin/*)
app.mount('/admin/*', (Context c, Next next) async {
  c.setRender((html, props) => c.html('''
    <html>
      <body class="admin">
        <nav>Admin Panel</nav>
        $html
      </body>
    </html>
  '''));
  await next();
});

app.get('/admin/dashboard', (Context c) {
  return c.render('<h1>Dashboard</h1>', {'title': 'Admin'});
});
```

---

## View Engine

For file-based templates (Mustache, Jinja, etc.) use the [`darto_view`](../darto_view/) package.  
It follows the same Hono-style pattern: register an engine once via middleware, then call `c.render()` in any handler.

```dart
import 'package:darto/darto.dart';
import 'package:darto_view/darto_view.dart';

void main() {
  final app = Darto();

  // Register the Mustache engine globally.
  app.use(viewEngine(MustacheEngine(viewsPath: 'views')));

  // c.render('templateName', data) — first arg is the file name (no extension).
  app.get('/', [], (c) => c.render('index', {
    'title': 'Home',
    'items': ['Routing', 'Middleware', 'Validation'],
  }));

  app.get('/about', [], (c) => c.render('about', {'title': 'About'}));

  app.listen(3000);
}
```

`views/index.mustache`:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>{{title}}</title>
  </head>
  <body>
    <ul>
      {{#items}}
      <li>{{name}}</li>
      {{/items}}
    </ul>
  </body>
</html>
```

- Templates are cached in memory after the first render.
- Scope to a path with `app.mount('/admin', viewEngine(...))`.
- Custom engines implement `TemplateEngine` — see [darto_view README](../darto_view/README.md).

---

## Request (`c.req`)

### URL info

```dart
String  method = c.req.method; // 'GET', 'POST', …
String  path   = c.req.path;   // '/users/42'
Uri     url    = c.req.url;    // full Uri
String  ip     = c.req.ip;     // remote IP
```

### Path parameters

```dart
String?  c.req.param('id')
int?     c.req.paramInt('id')
double?  c.req.paramDouble('id')
List<String?> c.req.params()   // all param values
```

### Query parameters

```dart
String?  c.req.query('page')
int?     c.req.queryInt('page')
double?  c.req.queryDouble('amount')
bool     c.req.queryBool('active')   // 'true'/'1'/'yes'/'on' → true
List<String> c.req.queries()         // all query values
```

### Headers

```dart
String? c.req.header('authorization')     // single header
Map<String, String> c.req.headers         // all headers (unmodifiable)
```

### Body

```dart
// JSON
final map  = await c.req.json();                     // Map<String, dynamic>
final dto  = await c.req.json<User>(User.fromJson);  // typed

// Raw
final bytes  = await c.req.blob();         // Uint8List
final buffer = await c.req.arrayBuffer(); // ByteBuffer

// Form
final form = await c.req.formData();      // Map (url-encoded) or String (multipart)
```

---

## Response Factories

Construct raw `Response` objects when you need full control:

```dart
Response.json(data, {int status = 200, Map<String, String> headers = const {}})
Response.text(str,  {int status = 200, Map<String, String> headers = const {}})
Response.html(str,  {int status = 200, Map<String, String> headers = const {}})
Response.bytes(bytes, {int status = 200, String contentType = '…', Map<String, String> headers = const {}})
const Response.empty({int status = 204})
```

---

## Middleware

### Global

```dart
app.use(logger());   // all routes
app.use(cors());     // call use() once per middleware
```

### Path-scoped

```dart
app.mount('/api/*', jwtMiddleware);
app.mount('/api/*', rateLimiter()); // call mount() once per middleware
```

### Route-level

```dart
app.get('/admin', [requireAdmin()], handler);
app.post('/upload', [bodyLimit(maxSize: 5 * 1024 * 1024)], handler);
```

### Writing a middleware

```dart
Middleware timer() => (Context c, Next next) async {
  final sw = Stopwatch()..start();
  await next();
  print('${c.req.method} ${c.req.path}  ${sw.elapsedMilliseconds}ms');
};
```

### Short-circuit (reject without calling `next`)

```dart
Middleware requireAdmin() => (Context c, Next next) async {
  if (c.user?['role'] != 'admin') {
    c.forbidden({'error': 'Admins only'});
    return; // pipeline stops here
  }
  await next();
};
```

---

## Built-in Middlewares

### Logger

```dart
import 'package:darto/logger.dart';

app.use(logger());                                 // prints to stdout
app.use(logger((msg, [rest]) => myLog.info(msg))); // custom printer
```

### CORS

```dart
import 'package:darto/cors.dart';

app.mount('/api/*', cors());  // permissive default (origin: *)

app.mount('/api/*', cors(
  origin: 'https://example.com',
  allowMethods: ['GET', 'POST', 'DELETE'],
  allowHeaders: ['Content-Type', 'Authorization'],
  exposeHeaders: ['X-Total-Count'],
  maxAge: 600,
  credentials: true,
));

// Dynamic origin
app.use(cors(
  originFn: (origin) => origin.endsWith('.example.com') ? origin : '*',
));

// Dynamic methods per origin
app.use(cors(
  allowMethodsFn: (origin, c) =>
      origin == 'https://admin.example.com'
          ? ['GET', 'POST', 'DELETE']
          : ['GET'],
));
```

### JWT Middleware

```dart
import 'package:darto/jwt.dart';

app.mount('/api/*', jwt(secret: 'mySecret'));

app.mount('/api/*', jwt(
  secret: env.jwtSecret,
  alg: 'HS512',
  cookie: 'access_token',      // read from cookie instead of header
  headerName: 'authorization', // default
  verifyOptions: VerifyOptions(
    iss: 'my-app',
    exp: true,
    nbf: true,
    iat: true,
  ),
));

// Payload available after middleware runs:
final payload = c.get<Map<String, dynamic>>('jwtPayload');
```

### Basic Auth

```dart
import 'package:darto/basic_auth.dart';

app.mount('/admin/*', basicAuth(username: 'admin', password: 'secret'));

app.mount('/admin/*', basicAuth(
  verifyUser: (user, pass, c) => user == 'admin' && pass == env.adminPass,
  onAuthSuccess: (c, username) => c.set('adminUser', username),
  realm: 'Admin Panel',
));
```

### Bearer Auth

```dart
import 'package:darto/bearer_auth.dart';

// Static token(s)
app.mount('/api/*', bearerAuth(token: 'my-api-key'));
app.mount('/api/*', bearerAuth(token: ['key1', 'key2']));

// Custom verification
app.mount('/api/*', bearerAuth(
  verifyToken: (token, c) async => await db.isValidApiKey(token),
));

// Full options
app.mount('/api/*', bearerAuth(
  verifyToken: (token, c) async => validateJwt(token),
  prefix: 'Bearer',
  headerName: 'authorization',
  noAuthenticationHeader: BearerAuthErrorOptions(
    message: (c) => {'error': 'No token provided'},
  ),
  invalidToken: BearerAuthErrorOptions(
    wwwAuthenticate: 'Bearer realm="API", error="invalid_token"',
  ),
));
```

### Cache

```dart
import 'package:darto/cache.dart';

app.get('*', cache(
  cacheName: 'my-app',
  cacheControl: 'max-age=3600',
));

app.get('/api/*', cache(
  cacheName: 'api-cache',
  wait: true,
  cacheableStatusCodes: [200, 203],
  keyGenerator: (c) => '${c.req.method}:${c.req.path}',
  onCacheNotAvailable: () => print('Cache unavailable'),
));
```

### Compress

```dart
import 'package:darto/compress.dart';

app.use(compress());

app.use(compress(
  encoding: 'gzip',   // 'gzip' (default) or 'deflate'
  threshold: 1024,    // minimum bytes to compress (default: 1024)
));
```

### CSRF

```dart
import 'package:darto/csrf.dart';

// Allow specific origin
app.use(csrf(origin: 'https://example.com'));

// Allow multiple origins
app.use(csrf(origins: ['https://app.com', 'https://admin.app.com']));

// Sec-Fetch-Site header check
app.use(csrf(secFetchSite: 'same-origin'));
app.use(csrf(secFetchSite: ['same-origin', 'same-site']));

// Dynamic
app.use(csrf(originFn: (origin) => origin.endsWith('.myapp.com')));
```

### Body Limit

```dart
import 'package:darto/body_limit.dart';

app.post('/upload', [
  bodyLimit(maxSize: 5 * 1024 * 1024), // 5 MB
], handler);

app.post('/upload', [
  bodyLimit(
    maxSize: 50 * 1024, // 50 KB
    onError: (c) => c.status(413).text('Payload too large'),
  ),
], handler);
```

### Optional JWT

Like `jwt()` but never rejects — populates `c.user` when a valid token is present, otherwise lets the request through. Useful for public routes that show personalised content when authenticated.

```dart
import 'package:darto/jwt.dart';

app.mount('/feed', optionalJwt(secret: env.secret));

app.get('/feed', (c) {
  final user = c.user; // null for anonymous, Map for authenticated
  return c.ok({'personalised': user != null});
});
```

### API Key Auth

```dart
import 'package:darto/api_key_auth.dart';

// Static key (default header: x-api-key)
app.mount('/api/*', apiKeyAuth(validate: (key) => key == env.apiKey));

// Multiple valid keys
final keys = {'key-a', 'key-b'};
app.mount('/api/*', apiKeyAuth(validate: keys.contains));

// Custom header
app.mount('/webhooks', apiKeyAuth(
  header: 'x-webhook-secret',
  validate: (key) => key == env.webhookSecret,
));
```

### Require Roles (RBAC)

Verifies that the authenticated user has **all** of the specified roles. Must run **after** a JWT middleware. Reads `c.user['roles']` as `List<String>`.

```dart
import 'package:darto/jwt.dart';
import 'package:darto/require_roles.dart';

app.delete('/posts/:id', [
  jwt(secret: env.secret),
  requireRoles(['admin']),
], deleteHandler);

// Multiple roles — user must have ALL of them
app.get('/reports', [
  jwt(secret: env.secret),
  requireRoles(['admin', 'auditor']),
], handler);
```

### Combine Middlewares

```dart
import 'package:darto/combine.dart';

// some — first middleware that passes wins (OR logic)
app.mount('/api/*', some(jwtMiddleware, apiKeyMiddleware));

// every — all must pass (AND logic)
app.mount('/admin/*', every(jwtMiddleware, requireAdmin()));

// except — skip middleware for matching paths/conditions
app.use(except('/health', logger()));
app.use(except(['/health', '/metrics'], rateLimiter()));
app.use(except((c) => c.req.method == 'OPTIONS', auth()));
```

---

## Validation

Request validation is provided by the [`darto_validator`](../darto_validator/) package via `zValidator` — a Hono `zod-validator`-style middleware backed by [zard](https://pub.dev/packages/zard).

```yaml
dependencies:
  darto_validator: ^1.0.0
```

```dart
import 'package:darto/darto.dart';
import 'package:darto_validator/darto_validator.dart';

final userSchema = z.map({
  'name':  z.string().min(1),
  'email': z.string().email(),
  'age':   z.int().min(0).max(150),
});

// Validates JSON body — handler runs only when schema passes
app.post('/users', [zValidator('json', userSchema)], (c) {
  final data = c.valid<Map<String, dynamic>>('json');
  return c.created({'user': data});
});

// Query params
app.get('/search', [zValidator('query', z.map({'q': z.string().min(1)}))], (c) {
  final q = c.valid<Map<String, dynamic>>('query');
  return c.ok({'query': q['q']});
});

// Route params
app.get('/posts/:id', [zValidator('param', z.map({'id': z.string()}))], (c) {
  final params = c.valid<Map<String, dynamic>>('param');
  return c.ok({'id': params['id']});
});
```

### Custom error via hook

```dart
app.post('/items', [
  zValidator('json', schema, (ZardResult result, c) {
    if (!result.success) {
      return c.status(422).json({'issues': result.error?.format()});
    }
    return null;
  }),
], handler);
```

### Targets

| `target` | Source |
|---|---|
| `'json'` | JSON body |
| `'query'` | URL query string |
| `'param'` | Route path parameters |
| `'form'` | Form body (urlencoded or multipart) |
| `'header'` | Request headers |

See [darto_validator README](../darto_validator/README.md) for full docs.

---

## File Upload

Darto handles `multipart/form-data` uploads directly in the handler via `c.req.parseBody()` — no middleware required.

### In-memory (small files)

Files are buffered as `Uint8List` and returned as `UploadedFile` objects. Ideal for avatars, images, and documents up to a few MB.

```dart
app.post('/avatar', [], (Context c) async {
  final body = await c.req.parseBody();
  final file = body['avatar'] as UploadedFile;

  print(file.name);     // 'photo.jpg'
  print(file.mimeType); // 'image/jpeg'
  print(file.size);     // bytes length

  // Write to disk when ready
  await File('uploads/${file.name}').writeAsBytes(file.bytes);

  return c.ok({'name': file.name, 'size': file.size});
});
```

### Streamed to disk (large files)

Pass `saveDir` to stream each file directly to disk without ever buffering it in memory. Recommended for videos, archives, and any file over a few MB.

```dart
app.post('/video', [], (Context c) async {
  final body = await c.req.parseBody(saveDir: 'uploads');
  final file = body['video'] as UploadedFile;

  // file.bytes is empty — data is already on disk
  print(file.path);     // 'uploads/1716123456789_video_482910374.mp4'
  print(file.size);     // file size in bytes
  print(file.isOnDisk); // true

  return c.ok({'path': file.path, 'size': file.size});
});
```

### Multiple files

When multiple parts share the same field name, the value becomes a `List<UploadedFile>`:

```dart
app.post('/gallery', [], (Context c) async {
  final body = await c.req.parseBody(saveDir: 'uploads');
  final raw   = body['photos'];
  final files = raw is List ? raw.cast<UploadedFile>() : [raw as UploadedFile];

  return c.ok({
    'count': files.length,
    'files': files.map((f) => {'name': f.name, 'size': f.size}).toList(),
  });
});
```

### Mixed fields and files

Text fields and files can appear in the same form:

```dart
app.post('/product', [], (Context c) async {
  final body = await c.req.parseBody(saveDir: 'uploads');
  final name  = body['name']  as String;
  final price = body['price'] as String;
  final image = body['image'] as UploadedFile;

  return c.created({
    'name':  name,
    'price': double.parse(price),
    'image': image.path,
  });
});
```

### `UploadedFile` reference

| Property    | Type        | Description                                        |
| ----------- | ----------- | -------------------------------------------------- |
| `fieldname` | `String`    | Form field name                                    |
| `name`      | `String`    | Original filename                                  |
| `bytes`     | `Uint8List` | File content (empty when `isOnDisk`)               |
| `mimeType`  | `String`    | MIME type from the part headers                    |
| `size`      | `int`       | File size in bytes                                 |
| `path`      | `String?`   | Absolute path on disk (set when `saveDir` is used) |
| `isOnDisk`  | `bool`      | `true` when the file was saved to disk             |

### `parseBody` supports all content types

| Content-Type                        | Value type                        |
| ----------------------------------- | --------------------------------- |
| `application/json`                  | `Map<String, dynamic>`            |
| `application/x-www-form-urlencoded` | `String` per field                |
| `multipart/form-data`               | `String` (text) or `UploadedFile` |

---

## File Download

Both `c.file()` and `c.download()` stream the file directly to the client using `Transfer-Encoding: chunked`. The full file is never loaded into memory — a 2 GB file uses the same constant amount of RAM as a 10 KB one.

### Serve a file inline

Auto-detects MIME type from the file extension and sends `Content-Length`:

```dart
app.get('/report', [], (Context c) async {
  return await c.file('reports/summary.pdf');
});

// Override MIME type
app.get('/data', [], (Context c) async {
  return await c.file('exports/data.bin', contentType: 'application/octet-stream');
});
```

### Force download

Adds `Content-Disposition: attachment` so the browser prompts a Save dialog:

```dart
app.get('/export', [], (Context c) async {
  return await c.download('exports/users.csv');
});

// Custom filename shown in the Save dialog
app.get('/export/:month', [], (Context c) async {
  final month = c.req.param('month');
  return await c.download('exports/$month.csv', filename: 'report-$month.csv');
});
```

Both methods return `404` automatically when the file does not exist.

---

## WebSocket

WebSocket support is provided by the [`darto_ws`](../darto_ws/) package.  
Routes upgrade on the **same port** as the HTTP server — no separate server or port needed.

```yaml
# pubspec.yaml
dependencies:
  darto_ws: ^1.0.0
```

### Basic echo

```dart
import 'package:darto/darto.dart';
import 'package:darto_ws/darto_ws.dart';

app.get('/ws', [], upgradeWebSocket((c) => WSHandler(
  onOpen:    (ws) => ws.send('connected'),
  onMessage: (event, ws) => ws.send('echo: ${event.text}'),
  onClose:   () => print('disconnected'),
  onError:   (err) => print('error: $err'),
)));
```

### Path params and middleware state

The `Context` is fully resolved before the upgrade — path params, headers, and any values set by upstream middleware are all available:

```dart
app.get('/chat/:room', [jwtMiddleware], upgradeWebSocket((c) {
  final room   = c.req.param('room')!;
  final userId = c.get<String>('userId'); // set by auth middleware

  return WSHandler(
    onOpen:    (ws) => ws.send('$userId joined "$room"'),
    onMessage: (event, ws) => ws.send('[$room] ${event.text}'),
  );
}));
```

### JSON messages

```dart
app.get('/ws/json', [], upgradeWebSocket((c) => WSHandler(
  onMessage: (event, ws) {
    final payload = event.json;           // Map<String, dynamic>
    ws.sendJson({'echo': payload});
  },
)));
```

### `WSHandler` callbacks

| Callback | Signature | When |
|---|---|---|
| `onOpen` | `(DartoWebSocket ws)` | Handshake complete |
| `onMessage` | `(WSEvent event, DartoWebSocket ws)` | Frame received |
| `onClose` | `()` | Connection closed |
| `onError` | `(Object error)` | Protocol error |

### `DartoWebSocket` methods

| Method | Description |
|---|---|
| `send(String)` | Send a text frame |
| `sendJson(Map)` | Encode and send as JSON |
| `sendBytes(List<int>)` | Send a binary frame |
| `close([code, reason])` | Close the connection |

---

## Helpers

### Validator

Generic validator middleware — Hono-style, available via `package:darto/validator.dart`.

`validate` receives the raw value extracted from the request and the `Context`. Return a `Response` to short-circuit with any status code, or return the parsed data to store it — retrieved with `c.valid<T>(target)`.

Use with [zard](https://pub.dev/packages/zard) (via [`darto_validator`](../darto_validator/)) for schema-driven validation with full control over the error response:

```dart
import 'package:darto/darto.dart';
import 'package:darto/validator.dart';
import 'package:darto_validator/darto_validator.dart';

final userSchema = z.map({
  'name':  z.string().min(1),
  'email': z.string().email(),
  'age':   z.int().min(0).max(150),
});

// 400 on failure — you decide the format
app.post('/users', [
  validator('json', (value, c) {
    final result = userSchema.safeParse(value);
    if (!result.success) return c.badRequest({'errors': result.error?.format()});
    return result.data;
  }),
], (Context c) {
  final data = c.valid<Map<String, dynamic>>('json');
  return c.created({'user': data});
});

// 401 on failure — any status code works
app.post('/login', [
  validator('json', (value, c) {
    final result = loginSchema.safeParse(value);
    if (!result.success) return c.status(401).json({'errors': result.error?.format()});
    return result.data;
  }),
], (Context c) {
  final credentials = c.valid<Map<String, dynamic>>('json');
  return c.ok({'message': 'Welcome, ${credentials['email']}!'});
});
```

Supports the same targets as `zValidator`: `'json'`, `'query'`, `'param'`, `'form'`, `'header'`.

| | `validator()` | `zValidator()` |
|---|---|---|
| Package | `darto` (core) | `darto_validator` |
| Schema library | you choose | zard (built-in) |
| Error response | you control | automatic `400` + optional hook |

> For automatic error responses without a callback, use [`zValidator`](../darto_validator/) from `darto_validator`.

---

### Cookie

```dart
import 'package:darto/cookie.dart';

// Read
Map<String, String> all = getCookies(c);
String? value = getCookie(c, 'session');

// Write
setCookie(c, 'session', 'abc123');
setCookie(c, 'session', 'abc123', CookieOptions(
  path: '/',
  httpOnly: true,
  secure: true,
  sameSite: 'Strict',
  maxAge: 3600,
  expires: DateTime.now().add(Duration(hours: 1)),
  domain: '.example.com',
));

// Delete
deleteCookie(c, 'session');

// Signed cookies (HMAC-SHA256)
await setSignedCookie(c, 'uid', '42', secret);
final uid = await getSignedCookie(c, secret, 'uid'); // null if tampered

// Generate without setting
String raw    = generateCookie('name', 'value', options);
String signed = await generateSignedCookie('name', 'value', secret);
```

### Session

Cookie-based signed sessions. Data is JSON-serialised, base64url-encoded, and signed with HMAC-SHA256 — tamper-proof but not encrypted (store only non-sensitive identifiers in the session).

```dart
import 'package:darto/session.dart';

// Register once globally — reads and validates the session cookie on every request
app.use(sessionMiddleware(
  secret: 'at-least-32-chars-long-secret!!',
  duration: 60 * 30,              // cookie maxAge in seconds (default: 1800)
  cookieName: 'darto.session',    // optional, this is the default
));

// Write / update — serialises data and sets the signed cookie
app.post('/login', [], (c) async {
  final body = await c.req.json();
  await sessionContext(c).update({'userId': body['id'], 'role': 'user'});
  return c.ok({'message': 'logged in'});
});

// Read
app.get('/me', [], (c) {
  final data = sessionContext(c).get(); // Map<String, dynamic>? — null if no session
  if (data == null) return c.unauthorized({'error': 'no session'});
  return c.ok(data);
});

// Delete — clears data and removes the cookie
app.post('/logout', [], (c) {
  sessionContext(c).delete();
  return c.ok({'message': 'logged out'});
});
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `secret` | `String` | required | HMAC-SHA256 signing key — use at least 32 random characters |
| `duration` | `int` | `1800` | Cookie `Max-Age` in seconds |
| `cookieName` | `String` | `'darto.session'` | Name of the session cookie |

| Method | Returns | Description |
|---|---|---|
| `sessionContext(c).get()` | `Map<String, dynamic>?` | Current session data; `null` if no valid session |
| `sessionContext(c).update(data)` | `Future<void>` | Replace session data and write the signed cookie |
| `sessionContext(c).delete()` | `void` | Clear session data and delete the cookie |

---

### JWT Helpers

```dart
import 'package:darto/jwt.dart';

// Build a payload
final payload = JwtPayload(
  sub: 'user123',
  exp: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300, // +5 min
  extra: {'role': 'admin', 'tenantId': 'acme'},
);

// Sign
final token = await sign(payload, 'mySecret');
final token = await sign(payload, 'mySecret', alg: 'HS512');
// also accepts Map<String, dynamic>:
final token = await sign({'sub': 'u1', 'exp': ...}, 'secret');

// Verify (throws JwtException on failure)
try {
  final claims = await verify(token, 'mySecret');
  print(claims['sub']); // 'user123'
} on JwtException catch (e) {
  print(e.message); // 'Token expired', 'Invalid signature', etc.
}

// Decode without verification
final [header, payload] = decode(token);
print(header['alg']); // 'HS256'
print(payload['sub']); // 'user123'
```

**JwtPayload fields:**

| Field   | Type                   | Description               |
| ------- | ---------------------- | ------------------------- |
| `sub`   | `String?`              | Subject                   |
| `iss`   | `String?`              | Issuer                    |
| `aud`   | `String?`              | Audience                  |
| `exp`   | `int?`                 | Expiration (Unix seconds) |
| `nbf`   | `int?`                 | Not-before (Unix seconds) |
| `iat`   | `int?`                 | Issued-at (Unix seconds)  |
| `jti`   | `String?`              | JWT ID                    |
| `extra` | `Map<String, dynamic>` | Custom claims             |

**Supported algorithms:** `HS256` (default), `HS384`, `HS512`.

### Route Helpers

```dart
import 'package:darto/route.dart';

app.get('/api/users/:id', [], (c) {
  print(routePath(c));      // '/api/users/:id'
  print(baseRoutePath(c));  // '/api'  (group prefix pattern)
  print(basePath(c));       // '/api'  (resolved with actual request values)

  final routes = matchedRoutes(c);
  // List<RouteSpec>: middleware routes + handler route that matched
  return c.ok({'total': routes.length});
});
```

### Proxy

```dart
import 'package:darto/proxy.dart';

// Transparent reverse proxy — forwards method, headers, and body
app.all('/api/*', [], (Context c) =>
    proxy(c, 'https://backend.com${c.req.path}'));

// With header overrides
app.get('/data', [], (Context c) async =>
    proxy(c, 'https://external.com/data',
        options: ProxyOptions(
            headers: {
                'Authorization': 'Bearer INTERNAL_TOKEN', // replace
                'Cookie': null,                            // remove
            },
        ),
    ),
);

// Disable automatic header/body forwarding
app.post('/webhook', [], (Context c) async =>
    proxy(c, 'https://service.com/hook',
        options: ProxyOptions(
            forwardHeaders: false,
            forwardBody: false,
            headers: {'X-Source': 'darto'},
        ),
    ),
);
```

**What `proxy` handles automatically:**

- Strips hop-by-hop headers (`Connection`, `Keep-Alive`, `Transfer-Encoding`, etc.)
- Manages `Accept-Encoding` for transparent gzip/deflate decompression
- Removes `Content-Encoding` and `Content-Length` from the upstream response (body is already decoded)
- Forwards the original HTTP method and request body

### Dev

```dart
import 'package:darto/dev.dart';

final app = Darto().basePath('/v1');

app.get('/posts', [], handler);
app.get('/posts/:id', [], handler);
app.post('/posts', [auth()], handler);

// Router name
print(getRouterName(app)); // 'Darto'

// Print route table
showRoutes(app);
// GET     /v1/posts
// GET     /v1/posts/:id
// POST    /v1/posts

// With colours and middleware counts
showRoutes(app, colorize: true, verbose: true);
// GET     /v1/posts
// GET     /v1/posts/:id
// POST    /v1/posts  [1 mw]
```

---

## HTTP Status Codes

```dart
import 'package:darto/darto.dart';

// 2xx
OK                   // 200
CREATED              // 201
ACCEPTED             // 202
NO_CONTENT           // 204

// 3xx
MOVED_PERMANENTLY    // 301
FOUND                // 302
NOT_MODIFIED         // 304

// 4xx
BAD_REQUEST          // 400
UNAUTHORIZED         // 401
FORBIDDEN            // 403
NOT_FOUND            // 404
METHOD_NOT_ALLOWED   // 405
CONFLICT             // 409
PAYLOAD_TOO_LARGE    // 413
UNPROCESSABLE_ENTITY // 422
TOO_MANY_REQUESTS    // 429

// 5xx
INTERNAL_SERVER_ERROR // 500
BAD_GATEWAY           // 502
SERVICE_UNAVAILABLE   // 503
GATEWAY_TIMEOUT       // 504
```

All status codes from RFC 9110 are available as top-level constants.

---

## Error Handling

```dart
// Custom global error handler
app.onError((DartoError err, Context c) {
  print(err.message);
  print(err.stackTrace);
  return c.internalError({'error': err.message});
});

// Custom 404 handler
app.notFound((Context c) {
  return c.notFound({'error': 'Route not found: ${c.req.path}'});
});
```

`DartoError` properties:

| Property     | Type         | Description                     |
| ------------ | ------------ | ------------------------------- |
| `cause`      | `Object`     | The original thrown object      |
| `stackTrace` | `StackTrace` | Stack trace from the throw site |
| `message`    | `String`     | `cause.toString()` shorthand    |

---

## CLI

The official CLI is available as a separate package — `darto_cli`.

```sh
dart pub global activate darto_cli
```

Make sure `~/.pub-cache/bin` is on your `PATH`.

### Scaffold a project

```sh
darto create my_api
cd my_api
```

Generates a ready-to-run project with a NestJS-style module structure:

```
my_api/
  bin/server.dart
  lib/
    app.dart
    config/env.dart
    modules/user/
      user_controller.dart
      user_service.dart
      user_repository.dart
      user_routes.dart
```

### Development server

```sh
darto dev              # watches lib/, bin/, src/ and auto-restarts on .dart changes
darto dev bin/main.dart
```

### Build for production

```sh
darto build                              # compile to build/server + generate Dockerfile
darto build --output build/my_server --no-docker
darto start                              # run the compiled binary
```

### Generate a typed Flutter/Dart client

```sh
darto gen client flutter
darto gen client flutter --output lib/src/api_client.dart --base-url https://api.example.com
```

Reads `createApp()` from `lib/app.dart`, introspects all registered routes, and emits a fully typed `ApiClient`:

```dart
final api = ApiClient(baseUrl: 'https://api.example.com');
api.setToken(accessToken);

final users = await api.users.getAll();
final user  = await api.users.getById('42');
await api.users.create(body: {'name': 'Alice'});
```

See [darto_cli](https://pub.dev/packages/darto_cli) and [darto_client_generator](https://pub.dev/packages/darto_client_generator) for full documentation.

---

## Examples

Ready-to-run projects are available in the [`examples/`](https://github.com/evandersondev/darto_framework/tree/main/examples) folder of the monorepo:

| Example | What it covers |
|---|---|
| [`example_basic_routing`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_basic_routing) | Route params, wildcards, optional params |
| [`example_group_routes`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_group_routes) | Route groups, nested groups, standalone routers |
| [`example_middleware_pipeline`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_middleware_pipeline) | Middleware chaining, short-circuit, `combine` |
| [`example_auth_jwt`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_auth_jwt) | JWT middleware, sign/verify helpers, `c.user` |
| [`example_middleware_validator`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_middleware_validator) | `zValidator` — schema-driven validation with zard |
| [`example_validator`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_validator) | `validator()` + zard — full control over the error response |
| [`example_context_usage`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_context_usage) | Full Context API, `c.req`, state, headers |
| [`example_response_helpers`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_response_helpers) | `c.ok`, `c.json`, `c.html`, `c.binary`, redirects |
| [`example_error_handling`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_error_handling) | `app.onError`, `app.notFound`, `DartoError` |
| [`example_upload`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_upload) | In-memory and streamed-to-disk file upload |
| [`example_static_files`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_static_files) | Static file serving with `darto_static` |
| [`example_view_engine`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_view_engine) | Mustache templates with `darto_view` |
| [`example_websocket`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_websocket) | WebSocket echo, JSON messages, room chat |
| [`example_session`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_session) | Cookie-based signed sessions |
| [`example_logger`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_logger) | Built-in logger middleware, custom printer |
| [`example_proxy`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_proxy) | Reverse proxy, header overrides |
| [`example_env`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_env) | `.env` loading with `darto_env` |
| [`example_full_integration`](https://github.com/evandersondev/darto_framework/tree/main/examples/example_full_integration) | Full app — auth, CORS, validation, WebSocket |

---

## Full Example

```dart
import 'package:darto/darto.dart';
import 'package:darto/cors.dart';
import 'package:darto/logger.dart';
import 'package:darto/jwt.dart';
import 'package:darto/body_limit.dart';

void main() async {
  final app = Darto().basePath('/v1');

  // Global middleware
  app.use(logger());
  app.mount('/api/*', cors(origin: 'https://myapp.com', credentials: true));

  // Health check (no auth)
  app.get('/health', [], (Context c) => c.ok({'status': 'ok'}));

  // JWT-protected API
  final api = app.group('/api');
  api.use(jwt(secret: 'super-secret'));

  api.get('/me', [], (Context c) {
    final payload = c.get<Map<String, dynamic>>('jwtPayload');
    return c.ok({'sub': payload['sub']});
  });

  api.route('/posts')
    .get([], (Context c) async {
      final page = c.req.queryInt('page') ?? 1;
      return c.ok({'page': page, 'posts': []});
    })
    .post([bodyLimit(maxSize: 100 * 1024)], (Context c) async {
      final body = await c.body();
      return c.created(body);
    });

  api.get('/posts/:id', [], (Context c) {
    final id = c.req.paramInt('id');
    if (id == null) return c.badRequest({'error': 'Invalid id'});
    return c.ok({'id': id});
  });

  // Error handlers
  app.onError((err, c) => c.internalError({'error': err.message}));
  app.notFound((c) => c.notFound({'error': 'Not found'}));

  await app.listen(3000, () => print('Listening on http://localhost:3000'));
}
```
