# darto_validator

Request validation middleware for [Darto](https://github.com/evandersondev/darto), powered by [zard](https://pub.dev/packages/zard) — a Zod-inspired schema library for Dart.

> For a generic validator without zard, use `validator()` from the core `darto` package.

---

## Install

```yaml
dependencies:
  darto: ^1.0.0
  darto_validator: ^1.0.0
```

`zard` is re-exported from `darto_validator`, so no separate dependency is needed.

---

## Quick start

```dart
import 'package:darto/darto.dart';
import 'package:darto_validator/darto_validator.dart';

final userSchema = z.map({
  'name':  z.string().min(1),
  'email': z.string().email(),
  'age':   z.int().min(0).max(150),
});

void main() {
  final app = Darto();

  app.post('/users', [zValidator('json', userSchema)], (Context c) {
    final data = c.req.valid<Map<String, dynamic>>('json');
    return c.created({'user': data});
  });

  app.listen(3000);
}
```

---

## `zValidator(target, schema, [hook])`

Validates data from a specific part of the request against a zard schema and stores the coerced result for the handler.

### Targets

| Target | Source |
|---|---|
| `'json'` | Request body (`application/json`) |
| `'query'` | URL query string parameters |
| `'param'` | Route path parameters (e.g. `/:id`) |
| `'form'` | Form body (`application/x-www-form-urlencoded` or `multipart/form-data`) |
| `'header'` | Request headers |

### Retrieve in handler — `c.req.valid<T>(target)`

```dart
// JSON body
app.post('/users', [zValidator('json', userSchema)], (c) {
  final data = c.req.valid<Map<String, dynamic>>('json');
  return c.created({'user': data});
});

// Query params
app.get('/search', [zValidator('query', z.map({'q': z.string().min(1)}))], (c) {
  final q = c.req.valid<Map<String, dynamic>>('query');
  return c.ok({'query': q['q']});
});

// Route params
app.get('/posts/:id', [zValidator('param', z.map({'id': z.string()}))], (c) {
  final params = c.req.valid<Map<String, dynamic>>('param');
  return c.ok({'id': params['id']});
});
```

### Hook — custom error handling

The optional third argument is called for **every** request — success or failure.
Return a `Response` to short-circuit; return `null` to fall through to default behaviour.

```dart
app.post('/items', [
  zValidator('json', schema, (ZardResult result, c) {
    if (!result.success) {
      return c.status(422).json({
        'message': 'Unprocessable entity',
        'issues': result.error?.format(),
      });
    }
    return null; // let it continue
  }),
], handler);
```

### Default error response (400)

When no hook is provided and validation fails:

```json
{
  "error": "Validation failed",
  "target": "json",
  "issues": ["name: Required", "email: Invalid email"]
}
```

---

## Schema DSL (`z`)

`z` is re-exported directly from `darto_validator`:

```dart
import 'package:darto_validator/darto_validator.dart';

final schema = z.map({
  'name':    z.string().min(1).max(100),
  'email':   z.string().email(),
  'age':     z.int().min(0).max(150),
  'active':  z.bool(),
  'score':   z.double().min(0),
  'tags':    z.list(z.string()),
  'role':    z.enumerate(['admin', 'user', 'guest']),
});
```

---

## API reference

| Symbol | Description |
|---|---|
| `zValidator(target, schema, [hook])` | Validation middleware — Hono `zod-validator`-style |
| `c.req.valid<T>(target)` | Retrieve validated data (from core `darto`) |
| `z` | Zard schema builder (re-exported) |
| `ZardResult` | Result type — `.success`, `.data`, `.error` |
| `schema.toOpenApiSchema()` | Convert a zard schema to an OpenAPI 3.1 Schema Object map |

---

## OpenAPI integration

Reuse a zard schema for documentation: `toOpenApiSchema()` converts it to an
OpenAPI 3.1 Schema Object map, ready for `darto_openapi`'s `Schema.raw(...)`.

```dart
import 'package:darto_openapi/darto_openapi.dart';

final userSchema = z.map({
  'name': z.string().min(2).max(50),
  'email': z.string().email(),
  'age': z.int().min(0).max(120).optional(),
});

api.post('/users',
  request: Req(json: Schema.raw(userSchema.toOpenApiSchema())),
  responses: {201: Res('Created')},
  handler: (c) => c.created(c.req.valid('json')),
);
```

It captures object shape + `required`, arrays, enums, nullability, defaults and
unions, **plus fine-grained constraints**: `minLength`/`maxLength`, `pattern`,
`format` (email, uri, uuid, date, time, date-time, ipv4, ipv6, hostname),
`minimum`/`maximum`, `multipleOf` and `minItems`/`maxItems`. So one zard schema
both validates requests and documents the API. Only arbitrary `refine`/
`transform` logic can't be represented in a schema and is omitted (it still
validates at runtime). Requires `zard: ^1.2.0`.

---

## See also

- [darto](https://github.com/evandersondev/darto) — core framework
- [zard](https://pub.dev/packages/zard) — schema library
- [examples/example_middleware_validator](../examples/example_middleware_validator/) — working example

<br/>

---

<br/>

### Support 💖

If you find Darto Validator useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the package and make it even better!

<br/>
