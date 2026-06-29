# darto_zard_openapi

Hono-style [`zod-openapi`](https://github.com/honojs/middleware/tree/main/packages/zod-openapi)
for [Darto](https://pub.dev/packages/darto), powered by
[zard](https://pub.dev/packages/zard).

Define a **zard** schema **once** and use it as the single source of truth: it
**validates** the request (real zard — `email`, `refine`, `z.coerce.*`, custom
messages) **and** generates the **OpenAPI 3.1** document. One import, contract
decoupled from the handler, Scalar UI included.

## Quick start

```dart
import 'package:darto_zard_openapi/darto_zard_openapi.dart';

// Define the schema once. .openapi(example:, description:) adds doc metadata per
// field — `example` is type-checked against the field's type. .openapiSchema('User')
// registers a reusable component (#/components/schemas/User).
final userSchema = z.map({
  'name':  z.string().min(1).openapi(example: 'Ada Lovelace', description: 'Full name'),
  'email': z.string().email().openapi(description: 'Contact e-mail'),
  'age':   z.int().min(0).max(150).openapi(example: 28),
}).openapiSchema('User');

final userIdParam = z.map({
  'id': z.coerce.int().min(1).openapi(description: 'User id'),
}).openapiSchema();

void main() async {
  final app = OpenAPIDarto();

  // Reusable route contract (≈ createRoute), decoupled from the handler.
  final getUser = createRoute(
    method: 'get',
    path: '/users/:id',
    summary: 'Get a user by id',
    request: Req(params: userIdParam),
    responses: [
      Res(200, 'User found', body: userSchema),
      Res(404, 'User not found'),
    ],
  );

  // Attach contract + middlewares + handler (≈ app.openapi).
  app.openapi(getUser, [], (c) {
    final id = c.req.valid<Map<String, dynamic>>('param')['id']; // int, validated
    if (id != 123) return c.status(404).json({'message': 'Not Found'});
    return c.ok({'id': 123, 'name': 'Ada Lovelace', 'age': 28});
  });

  app.doc('/openapi.json', info: Info(title: 'Users API', version: '1.0.0'));
  app.get('/docs', [], scalarUI(url: '/openapi.json'));

  await app.listen(3000);
}
```

## How it maps to `@hono/zod-openapi`

| `@hono/zod-openapi` | `darto_zard_openapi` |
|---|---|
| `new OpenAPIHono()` | `OpenAPIDarto()` |
| `createRoute({...})` | `createRoute(...)` |
| `app.openapi(route, handler)` | `app.openapi(route, [middlewares], handler)` |
| `field.openapi({example, description})` | `field.openapi(example:, description:)` (type-safe `example`) |
| `schema.openapi('User')` | `schema.openapiSchema('User')` |
| `c.req.valid('param')` | `c.req.valid<...>('param')` |
| `app.doc('/openapi.json', {...})` | `app.doc('/openapi.json', info:, servers:)` |
| `swaggerUI({url})` | `scalarUI(url:)` |

## Notes

- **Validation** is done by the zard schemas via Darto's `validator` middleware.
  On failure the request short-circuits with `400 {error, target, issues}`.
- **Params / query / headers** are object schemas whose properties each become an
  OpenAPI parameter. These values arrive as strings, so use `z.coerce.*` for
  non-string types (e.g. `z.coerce.int()`).
- **Typing**: Dart can't infer a schema's shape at runtime, so `c.req.valid<T>()`
  takes an explicit `T` (e.g. `Map<String, dynamic>`).
- `refine`/`transform` validate at runtime but can't be represented in the spec.
