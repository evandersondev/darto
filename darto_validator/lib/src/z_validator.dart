import 'dart:async';

import 'package:darto/darto.dart';
import 'package:darto/src/middlewares/validator.dart';
import 'package:zard/zard.dart';

// ── Middleware ─────────────────────────────────────────────────────────────────

/// Zard schema validator — Hono `zod-validator`-style middleware for Darto.
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
/// app.post('/users', [zValidator('json', userSchema)], (c) {
///   final data = c.valid<Map<String, dynamic>>('json');
///   return c.created({'user': data});
/// });
///
/// // Query params
/// app.get('/search', [zValidator('query', z.map({'q': z.string().min(1)}))], (c) {
///   final q = c.valid<Map<String, dynamic>>('query');
///   return c.ok({'query': q['q']});
/// });
///
/// // Route params
/// app.get('/posts/:id', [zValidator('param', z.map({'id': z.string()}))], (c) {
///   final params = c.valid<Map<String, dynamic>>('param');
///   return c.ok({'id': params['id']});
/// });
///
/// // Custom error via hook — return 422 instead of 400
/// app.post('/items', [
///   zValidator('json', schema, (result, c) {
///     if (!result.success) {
///       return c.status(422).json({'issues': result.error?.format()});
///     }
///     return null;
///   }),
/// ], handler);
/// ```
Middleware zValidator(
  String target,
  Schema schema, [
  FutureOr<Response?> Function(ZardResult result, Context c)? hook,
]) {
  return (Context c, Next next) async {
    final input = await extractValidatorInput(target, c);
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

    c.set(validatorKey(target), result.data);
    await next();
  };
}
