# darto_openapi

OpenAPI 3.1 spec generation and **Scalar** API docs for the
[Darto](https://pub.dev/packages/darto) web framework.

Describe a route **once** — it is mounted on the app (validating the request
body) and recorded for the generated OpenAPI document. One source of truth for
**validation** and **documentation**.

## Install

```yaml
dependencies:
  darto_openapi: ^1.0.0
```

## Usage

```dart
import 'package:darto/darto.dart';
import 'package:darto_openapi/darto_openapi.dart';

void main() async {
  final app = Darto();
  final api = OpenApi(
    app,
    info: Info(title: 'Blog API', version: '1.0.0'),
    servers: [Server('http://localhost:3000')],
  );

  api.get('/posts/:id',
    summary: 'Get a post',
    tags: ['posts'],
    request: Req(params: {'id': Schema.integer()}),
    responses: {200: Res('A post', body: Schema.object({'id': Schema.integer()}))},
    handler: (c) => c.ok({'id': c.req.paramInt('id')}),
  );

  api.post('/posts',
    summary: 'Create a post',
    tags: ['posts'],
    request: Req(json: Schema.object({
      'title': Schema.string(minLength: 1),
      'tags':  Schema.array(Schema.string()),
    }, required: ['title'])),
    responses: {201: Res('Created')},
    handler: (c) => c.created(c.req.valid<Map<String, dynamic>>('json')),
  );

  app.use(api.docs()); // GET /openapi.json + GET /docs (Scalar UI)
  await app.listen(3000);
}
```

- `GET /openapi.json` → the OpenAPI 3.1 document.
- `GET /docs` → the Scalar API reference (assets loaded from CDN).

## Schemas

`Schema` builders are stored as data, so the same definition both **validates**
and is **emitted** into the spec:

```dart
Schema.string(minLength: 1, maxLength: 80, format: 'email');
Schema.integer(minimum: 0, maximum: 150);
Schema.number(minimum: 0);
Schema.boolean();
Schema.array(Schema.string(), minItems: 1);
Schema.object({'name': Schema.string()}, required: ['name']);
Schema.raw({'type': 'string'}); // escape hatch: raw OpenAPI Schema Object
```

When a route declares `request: Req(json: schema)`, the body is validated
(responding `400` with `issues` on failure) and the parsed value is available
via `c.req.valid('json')`.

## Security schemes

```dart
final api = OpenApi(app,
  info: Info(title: 'API', version: '1.0.0'),
  securitySchemes: {
    'bearerAuth': SecurityScheme.bearer(),                 // http / bearer / JWT
    'apiKey':     SecurityScheme.apiKey(name: 'X-API-Key'),
  },
);

api.get('/me',
  security: ['bearerAuth'],
  responses: {200: Res('Current user')},
  handler: (c) => c.ok({'id': 1}),
);
```

Schemes are emitted under `components.securitySchemes`; `security: [...]` adds
the requirement to a route's operation.

## Validation

`json` (body), `params` (path), `query` and `headers` are validated when a
schema is declared. Path/query/header values are coerced from strings to the
declared scalar type; `query`/`headers` are optional when absent. On failure the
response is `400` with `issues` grouped by target; on success the parsed value
is available via `c.req.valid('<target>')`.

## Typed client (end-to-end)

`generateDartClient(spec)` turns the OpenAPI document into a **typed Dart client** —
model classes (with `fromJson`/`toJson`) for request/response bodies and a typed
method per operation. So the schemas you declare on the server flow all the way to
a typed client. The generated client uses only `dart:io` + `dart:convert`.

```dart
import 'dart:io';
import 'package:darto_openapi/darto_openapi.dart';

// In a dev script / build step:
final source = generateDartClient(api.toJson(), baseUrl: 'https://api.example.com');
File('lib/api_client.dart').writeAsStringSync(source);
```

Given a `POST /posts` with a `title` body and an `id` response, you get:

```dart
final api = ApiClient();
final post = await api.postPosts(PostPostsRequest(title: 'Hello'));
print(post.id); // typed int
```

## API

| Type | Purpose |
|---|---|
| `OpenApi(app, {info, servers, securitySchemes})` | Registry; `get`/`post`/`put`/`patch`/`delete`, `toJson()`, `docs()` |
| `Info` / `Server` | Document metadata |
| `Req({json, params, query, headers})` | Request contract (validates all four) |
| `Res(description, {body, contentType})` | Documented response |
| `SecurityScheme` | `bearer` / `basic` / `apiKey` / `http` |
| `Schema` | Schema builder + validator + OpenAPI generator |

> Reuse `zard` schemas via `darto_validator`'s `schema.toOpenApiSchema()` +
> `Schema.raw(...)`. Next up: `$ref`/components dedup.

<br/>

---

<br/>

### Support 💖

If you find Darto OpenAPI useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the package and make it even better!

<br/>
