---
name: darto-validate-request
description: Validate the body, query, params, or headers of a Darto (Dart) request using the zValidator middleware and zard (Zod-style) schemas. Use when adding input validation to a Darto endpoint, defining a z.map/z.string/z.int schema, reading validated data with c.req.valid, or customizing the validation error response. Requires the darto_validator package.
---

# Validate a request in Darto

Validation in Darto is a **route middleware**, `zValidator`, from the
`darto_validator` package. It validates one part of the request against a
[`zard`](https://pub.dev/packages/zard) schema (Zod-style). When validation
passes, the handler runs and reads the parsed data via `c.req.valid(...)`. When
it fails, the request is rejected before the handler runs.

## Setup

```yaml
# pubspec.yaml
dependencies:
  darto: ^1.2.0
  darto_validator: ^1.0.0   # re-exports `zard`; no separate zard dependency
```

```dart
import 'package:darto/darto.dart';
import 'package:darto_validator/darto_validator.dart'; // gives you z.* and zValidator
```

## Procedure

1. **Define a schema** with `z`:
   ```dart
   final userSchema = z.map({
     'name':  z.string().min(1),
     'email': z.string().email(),
     'age':   z.int().min(0).max(150),
   });
   ```
2. **Attach `zValidator(target, schema)` as route middleware.** The handler runs
   only if validation succeeds:
   ```dart
   app.post('/users', [zValidator('json', userSchema)], (Context c) {
     final data = c.req.valid<Map<String, dynamic>>('json');
     return c.created({'user': data});
   });
   ```
3. **Read the validated data** in the handler with the **same target string**:
   `c.req.valid<Map<String, dynamic>>('json' | 'query' | 'param' | 'header')`.
   Use the validated value — not the raw `c.req.json()` — so you get the parsed
   / coerced result.

## Targets

| `target`  | Validates                         |
| --------- | --------------------------------- |
| `'json'`  | JSON request body                 |
| `'query'` | query-string parameters           |
| `'param'` | path parameters                   |
| `'header'`| request headers                   |

```dart
// Query
app.get('/search', [zValidator('query', z.map({'q': z.string().min(1)}))], (c) {
  final q = c.req.valid<Map<String, dynamic>>('query');
  return c.ok({'query': q['q']});
});

// Path param
app.get('/posts/:id', [zValidator('param', z.map({'id': z.string()}))], (c) {
  final params = c.req.valid<Map<String, dynamic>>('param');
  return c.ok({'id': params['id']});
});
```

## Coercion (string → number/bool)

Query and path params arrive as **strings**. To validate them as numbers/bools,
use coercing schemas so the parsed result is the right Dart type:

```dart
// '/items/42' → params['id'] is an int, not a String
final idSchema = z.map({'id': z.coerce.int().min(1)});
app.get('/items/:id', [zValidator('param', idSchema)], (c) {
  final parsed = c.req.valid<Map<String, dynamic>>('param'); // same target as zValidator
  return c.ok({'id': parsed['id']}); // parsed['id'] is an int
});
```

Read the coerced value through `c.req.valid(...)`; the raw `c.req.param(...)`
is still the original string.

## Custom error response

Pass a third argument — a hook that receives the `ZardResult` and the context.
Return a `Response` to override the default error, or `null` to fall through:

```dart
app.post('/items', [
  zValidator('json', schema, (ZardResult result, c) {
    if (!result.success) {
      return c.status(422).json({'issues': result.error?.format()});
    }
    return null; // success → continue to handler
  }),
], handler);
```

## Complete example

```dart
import 'package:darto/darto.dart';
import 'package:darto_validator/darto_validator.dart';

final createUser = z.map({
  'name':  z.string().min(1),
  'email': z.string().email(),
});

void main() {
  final app = Darto();

  app.post('/users', [zValidator('json', createUser)], (Context c) {
    final data = c.req.valid<Map<String, dynamic>>('json');
    return c.created({'user': data});
  });

  app.listen(3000);
}
```

## Notes

- `zValidator` validates **one** target per middleware; stack multiple in the
  list to validate several (e.g. `[zValidator('query', q), zValidator('json', b)]`).
- The handler never runs on validation failure — no need to re-check inside it.
- For full control of the response shape, prefer the error hook over try/catch.
