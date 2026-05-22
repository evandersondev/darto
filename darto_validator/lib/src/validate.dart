import 'package:darto/darto.dart';
import 'package:zard/zard.dart';

/// Validates the request body against [schema].
///
/// On success stores the parsed value in `c.set('validated', data)`.
/// On failure responds with 400 — handler is never called.
///
/// ```dart
/// final schema = z.map({'name': z.string().min(1), 'email': z.string().email()});
///
/// r.post('/users', createUser, [validate(schema)]);
/// ```
Middleware validate(Schema schema, {String key = 'validated'}) {
  return (Context c, Next next) async {
    final data = await c.body();
    final result = await schema.safeParseAsync(data);
    if (!result.success) {
      c.badRequest({
        'error': 'Validation failed',
        'details': result.error?.format(),
      });
      return;
    }
    c.set(key, result.data);
    await next();
  };
}

/// Validates the query string.
Middleware validateQuery(Schema schema, {String key = 'validatedQuery'}) {
  return (Context c, Next next) async {
    final result = await schema.safeParseAsync(c.req.url.queryParameters);
    if (!result.success) {
      c.badRequest({
        'error': 'Validation failed',
        'details': result.error?.format(),
      });
      return;
    }
    c.set(key, result.data);
    await next();
  };
}
