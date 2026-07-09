import 'package:darto/darto.dart';
import 'package:zard/zard.dart';

/// A custom error mapper for [errorBridge].
///
/// Receives the thrown [error] and the current [Context]. Return a [Response]
/// to handle the error, or `null` to fall through to the next mapper (and
/// ultimately to the built-in mappers / 500 fallback).
///
/// ```dart
/// ErrorMapper myMapper = (error, c) {
///   if (error is MyDomainError) return c.status(418).json({'error': 'teapot'});
///   return null; // let the next mapper try
/// };
/// ```
typedef ErrorMapper = Response? Function(Object error, Context c);

/// Bridges typed errors thrown anywhere downstream into coherent HTTP
/// responses — a single place to translate exceptions into status codes.
///
/// Lives in `darto_validator` (not darto core) so the core stays free of a
/// zard dependency; you already depend on `darto_validator` whenever you use
/// zard-based validation.
///
/// Register it as the **outermost** middleware so it wraps the whole pipeline:
///
/// ```dart
/// app.use(errorBridge());
/// ```
///
/// ## Resolution order
///
/// For each thrown error, mappers are tried in this order; the first one to
/// return a non-null [Response] wins:
///
/// 1. **[mappers]** — your custom [ErrorMapper]s, in order. Use these for your
///    own domain errors or to override any of the defaults below.
/// 2. **zard [ZardError]** → `422 Unprocessable Entity` with body
///    `{"issues": [ ... ]}`, one map per [ZardIssue]
///    (`message`, `type`, `path`, `value`).
/// 3. **Duck-typed ORM / database errors** — matched *by runtime type name*
///    (best-effort, so this does not hard-depend on any ORM such as
///    dartonic). The following substrings in `error.runtimeType.toString()`
///    are recognized:
///
///    | Runtime type contains   | Status | Meaning                        |
///    |-------------------------|--------|--------------------------------|
///    | `UniqueViolationError`  | 409    | Conflict (unique constraint)   |
///    | `ForeignKeyError`       | 409    | Conflict (FK constraint)       |
///    | `NotNullViolationError` | 400    | Bad Request (NOT NULL)         |
///    | `ConnectionError`       | 503    | Service Unavailable (DB down)  |
///
/// 4. **Fallback** — the error is re-thrown so the framework's
///    [Darto.onError] handler (if any) runs; otherwise Darto's default 500
///    response is produced.
///
/// The duck-typing is intentionally loose so it works with third-party ORMs
/// living in separate packages. If you need exact type matching or different
/// status codes, pass a custom [ErrorMapper] in [mappers] — it runs first and
/// wins.
Middleware errorBridge({List<ErrorMapper> mappers = const []}) {
  return (Context c, Next next) async {
    try {
      await next();
    } catch (error, _) {
      // 1. Custom mappers first — they can override any default.
      for (final mapper in mappers) {
        final r = mapper(error, c);
        if (r != null) {
          c.respond(r);
          return;
        }
      }

      // 2. zard validation errors.
      if (error is ZardError) {
        c.respond(Response.json(
          {
            'issues': [
              for (final issue in error.issues)
                {
                  'message': issue.message,
                  'type': issue.type,
                  'path': issue.path,
                  'value': issue.value,
                }
            ],
          },
          status: 422,
        ));
        return;
      }

      // 3. Duck-typed ORM / database errors (best-effort, name-based).
      final typeName = error.runtimeType.toString();
      final mapped = _mapByTypeName(typeName, error, c);
      if (mapped != null) {
        c.respond(mapped);
        return;
      }

      // 4. Unknown → let the framework's onError / default 500 handle it.
      rethrow;
    }
  };
}

/// Maps a database/ORM error to a [Response] purely by its runtime type name.
/// Returns `null` when the name is not recognized.
Response? _mapByTypeName(String typeName, Object error, Context c) {
  int? status;
  if (typeName.contains('UniqueViolationError')) {
    status = 409;
  } else if (typeName.contains('ForeignKeyError')) {
    status = 409;
  } else if (typeName.contains('NotNullViolationError')) {
    status = 400;
  } else if (typeName.contains('ConnectionError')) {
    status = 503;
  }
  if (status == null) return null;
  return Response.json({'error': error.toString()}, status: status);
}
