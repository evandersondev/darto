import 'dart:async';

import 'package:darto/darto.dart';
import 'package:zard/zard.dart';

// ── Storage key ───────────────────────────────────────────────────────────────

String _key(String target) => '__zv_$target';

// ── Extension ─────────────────────────────────────────────────────────────────

/// Retrieves the value validated by [zValidator] for [target].
///
/// Must be called in a handler that runs after `zValidator(target, schema)`.
///
/// ```dart
/// app.post('/users', createUser, [zValidator('json', schema)]);
///
/// Response createUser(Context c) {
///   final data = c.valid<Map<String, dynamic>>('json');
///   return c.created({'user': data});
/// }
/// ```
extension ZValidatorContext on Context {
  T valid<T>(String target) => get<T>(_key(target));
}

// ── Middleware ─────────────────────────────────────────────────────────────────

/// Zard schema validator — Hono `zValidator`-style middleware for Darto.
///
/// [target] selects where to read data from:
///
/// | Value | Source |
/// |---|---|
/// | `'json'` | Request body (`application/json`) |
/// | `'query'` | URL query parameters |
/// | `'param'` | Route path parameters (e.g. `/:id`) |
/// | `'form'` | Form body (`application/x-www-form-urlencoded` or `multipart/form-data`) |
/// | `'header'` | Request headers |
///
/// On **success** — stores the coerced value; retrieve it with `c.valid<T>(target)`.
///
/// On **failure** — responds `400` with a JSON error body (unless [hook] handles it).
///
/// The optional [hook] is invoked on **every** request — success or failure.
/// Return a [Response] from the hook to short-circuit the pipeline.
/// Return `null` to fall through to default behaviour.
///
/// ```dart
/// // Basic usage
/// app.post('/users', createUser, [
///   zValidator('json', z.object({
///     'name':  z.string().min(1),
///     'email': z.string().email(),
///   })),
/// ]);
///
/// Response createUser(Context c) {
///   final data = c.valid<Map<String, dynamic>>('json');
///   return c.created({'user': data});
/// }
///
/// // Query params
/// app.get('/search', handler, [
///   zValidator('query', z.object({'q': z.string().min(1)})),
/// ]);
///
/// // Route params
/// app.get('/posts/:id', handler, [
///   zValidator('param', z.object({'id': z.string().min(1)})),
/// ]);
///
/// // Custom error via hook — return 422 instead of 400
/// app.post('/items', handler, [
///   zValidator('json', schema, (result, c) {
///     if (!result.success) {
///       return c.status(422).json({'issues': result.error?.format()});
///     }
///     return null;
///   }),
/// ]);
/// ```
Middleware zValidator(
  String target,
  Schema schema, [
  FutureOr<Response?> Function(ZardResult result, Context c)? hook,
]) {
  return (Context c, Next next) async {
    final input = await _extract(target, c);
    final result = schema.safeParse(input);

    if (hook != null) {
      final hookResponse = await hook(result, c);
      if (hookResponse != null) {
        c.respond(hookResponse);
        return;
      }
    }

    if (!result.success) {
      c.status(400).json({
        'error': 'Validation failed',
        'target': target,
        'issues': result.error?.format(),
      });
      return;
    }

    c.set(_key(target), result.data);
    await next();
  };
}

// ── Data extraction ───────────────────────────────────────────────────────────

Future<dynamic> _extract(String target, Context c) async {
  switch (target) {
    case 'json':
      return await c.body();
    case 'query':
      return c.req.url.queryParameters;
    case 'param':
    case 'params':
      return c.req.paramsMap;
    case 'form':
      return await c.req.parseBody();
    case 'header':
      return c.req.headers;
    default:
      throw ArgumentError(
        'zValidator: unknown target "$target". '
        'Valid targets: json, query, param, form, header.',
      );
  }
}
