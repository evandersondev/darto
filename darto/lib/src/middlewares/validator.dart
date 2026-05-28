import 'dart:async';

import 'package:darto/darto.dart';

// ── Storage key (must match Context.valid) ────────────────────────────────────

String validatorKey(String target) => '__v_$target';

// ── Data extraction ───────────────────────────────────────────────────────────

Future<dynamic> extractValidatorInput(String target, Context c) async {
  switch (target) {
    case 'json':
      return await c.req.json();
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
        'validator: unknown target "$target". '
        'Valid targets: json, query, param, form, header.',
      );
  }
}

// ── Middleware ────────────────────────────────────────────────────────────────

/// Generic validator middleware — Hono-style, use any validation logic.
///
/// [target] selects the input source:
///
/// | Value | Source |
/// |---|---|
/// | `'json'` | Request body (`application/json`) |
/// | `'query'` | URL query parameters |
/// | `'param'` | Route path parameters (e.g. `/:id`) |
/// | `'form'` | Form body (`application/x-www-form-urlencoded` or `multipart/form-data`) |
/// | `'header'` | Request headers |
///
/// [validate] receives the raw extracted value and the [Context]. Return:
/// - A **[Response]** to short-circuit the pipeline (e.g. error response).
/// - **Any other value** to store it; retrieve with `c.req.valid<T>(target)`.
///
/// ```dart
/// import 'package:darto/darto.dart';
/// import 'package:darto/validator.dart';
///
/// app.post('/posts', [
///   validator('json', (value, c) {
///     final body = value as Map<String, dynamic>;
///     if (body['title'] == null) return c.badRequest({'error': 'title is required'});
///     return body;
///   }),
/// ], (Context c) {
///   final data = c.req.valid<Map<String, dynamic>>('json');
///   return c.created({'post': data});
/// });
/// ```
///
/// Works with any library — custom logic, [zard](https://pub.dev/packages/zard),
/// etc. To use zard schemas just add `zard` to your pubspec (you do **not** need
/// the `darto_validator` package — that's only for `zValidator`):
///
/// ```dart
/// import 'package:zard/zard.dart'; // add `zard` to pubspec — for z.*
///
/// final schema = z.map({'name': z.string().min(1)});
///
/// app.post('/users', [
///   validator('json', (value, c) {
///     final result = schema.safeParse(value);
///     if (!result.success) return c.text('Invalid!', 401);
///     return result.data;
///   }),
/// ], (Context c) {
///   final data = c.req.valid<Map<String, dynamic>>('json');
///   return c.created({'user': data});
/// });
/// ```
Middleware validator(
  String target,
  FutureOr<dynamic> Function(dynamic value, Context c) validate,
) {
  return (Context c, Next next) async {
    final input = await extractValidatorInput(target, c);
    final result = await validate(input, c);

    if (result is Response) {
      c.respond(result);
      return;
    }

    c.set(validatorKey(target), result);
    await next();
  };
}
