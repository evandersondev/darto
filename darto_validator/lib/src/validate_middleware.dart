import 'package:darto/darto.dart';
import 'package:zard/zard.dart';

/// Validates the request body (default), query string, or route params
/// against a [Zard](https://pub.dev/packages/zard) schema.
///
/// On **success** — stores the parsed/coerced value in `req.context` under
/// the key `'validated'` (or a custom [key]) and calls `next()`.
///
/// On **failure** — responds with HTTP 400 and a JSON error body; `next()` is
/// NOT called so the route handler never runs.
///
/// ```dart
/// import 'package:zard/zard.dart';
/// import 'package:darto_validator/darto_validator.dart';
///
/// final createUserSchema = z.object({
///   'name':  z.string().min(1),
///   'email': z.string().email(),
/// });
///
/// router.post('/users', validate(createUserSchema), (req) async {
///   final data = req.get('validated') as Map<String, dynamic>;
///   return userService.create(data);
/// });
/// ```
Middleware validate(
  Schema schema, {
  /// Where to read data from.  Defaults to `'body'`.
  /// Accepted values: `'body'`, `'query'`, `'params'`.
  String source = 'body',

  /// Key used to store the validated value in `req.context`.
  /// Defaults to `'validated'`.
  String key = 'validated',
}) {
  return (Context c, Next next) async {
    dynamic data;

    switch (source) {
      case 'query':
        data = c.req.query;
      case 'params':
        data = c.req.param;
      default:
        data = await c.body();
    }

    final result = await schema.safeParseAsync(data);

    if (!result.success) {
      c.status(400).json({
        'error': 'Validation failed',
        'source': source,
        'details': result.error?.format(),
      });
      return;
    }

    c.req.set(key, result.data);
    next();
  };
}

/// Shorthand — validates only the request body.
Middleware validateBody(Schema schema, {String key = 'validated'}) =>
    validate(schema, source: 'body', key: key);

/// Shorthand — validates only the query string.
Middleware validateQuery(Schema schema, {String key = 'validatedQuery'}) =>
    validate(schema, source: 'query', key: key);

/// Shorthand — validates only the route params.
Middleware validateParams(Schema schema, {String key = 'validatedParams'}) =>
    validate(schema, source: 'params', key: key);
