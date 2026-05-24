import 'package:darto/darto.dart';

// ── some ──────────────────────────────────────────────────────────────────────

/// Runs each middleware in order and short-circuits on the **first one that
/// passes** (i.e. calls `next()`).
///
/// If a middleware rejects (sets a response without calling `next()`), it is
/// skipped and the next candidate is tried.  Only when **all** middlewares
/// reject does the combined middleware fail — keeping the last rejection
/// response.
///
/// Typical use: "if the client has a valid token, skip rate-limiting; otherwise
/// apply rate-limiting."
///
/// ```dart
/// app.mount('/api/*', some(
///   bearerAuth(token: token),
///   myRateLimit(limit: 100),
/// ));
///
/// // Nested composition:
/// app.mount('/api/*', some(
///   myCheckLocalNetwork(),
///   every(bearerAuth(token: token), myRateLimit(limit: 100)),
/// ));
/// ```
Middleware some(
  Middleware first,
  Middleware second, [
  Middleware? third,
  Middleware? fourth,
  Middleware? fifth,
]) {
  final middlewares = [
    first,
    second,
    if (third != null) third,
    if (fourth != null) fourth,
    if (fifth != null) fifth,
  ];

  return (Context c, Next next) async {
    Object? lastError;

    for (int i = 0; i < middlewares.length; i++) {
      final isLast = i == middlewares.length - 1;
      var called = false;

      try {
        await middlewares[i](c, () async {
          called = true;
        });

        if (called) {
          // This middleware passed — clear any stale rejection and proceed.
          c.clearResponse();
          await next();
          return;
        }

        // Soft rejection (set a response without calling next).
        lastError = null;
        if (!isLast) c.clearResponse();
      } catch (e) {
        if (called) {
          // Error occurred after calling next — unexpected, rethrow.
          rethrow;
        }
        lastError = e;
        if (!isLast) c.clearResponse();
      }
    }

    final err = lastError;
    if (err != null) throw err;
    // All middlewares rejected; c._response holds the last rejection.
  };
}

// ── every ─────────────────────────────────────────────────────────────────────

/// Runs **all** middlewares in sequence and proceeds only when every one of
/// them passes (calls `next()`).
///
/// As soon as any middleware rejects (sets a response without calling `next()`
/// or throws), the chain is stopped and the rejection is returned immediately.
///
/// ```dart
/// // Both bearerAuth AND rateLimit must pass:
/// app.mount('/api/*', every(
///   bearerAuth(token: token),
///   myRateLimit(limit: 100),
/// ));
/// ```
Middleware every(
  Middleware first,
  Middleware second, [
  Middleware? third,
  Middleware? fourth,
  Middleware? fifth,
]) {
  final middlewares = [
    first,
    second,
    if (third != null) third,
    if (fourth != null) fourth,
    if (fifth != null) fifth,
  ];

  return (Context c, Next next) async {
    Future<void> dispatch(int i) async {
      if (i >= middlewares.length) {
        await next();
        return;
      }

      await middlewares[i](c, () async {
        await dispatch(i + 1);
      });

      // If the middleware did not call next, it rejected — stop the chain.
    }

    await dispatch(0);
  };
}

// ── except ────────────────────────────────────────────────────────────────────

/// Skips [middleware] (calls `next()` directly) whenever [condition] matches
/// the current request; otherwise runs [middleware] normally.
///
/// [condition] can be:
/// - A `String` path pattern, where `*` acts as a wildcard (e.g. `/api/public/*`).
/// - A `List` of path patterns and/or `bool Function(Context)` predicates
///   (the middleware is skipped when **any** element matches — OR logic).
/// - A `bool Function(Context c)` predicate.
///
/// ```dart
/// // Skip auth for public routes:
/// app.mount('/api/*', except(
///   '/api/public/*',
///   bearerAuth(token: token),
/// ));
///
/// // Multiple exclusions:
/// app.use(except(
///   ['/health', '/api/public/*'],
///   bearerAuth(token: token),
/// ));
///
/// // Custom predicate:
/// app.use(except(
///   (c) => c.req.method == 'OPTIONS',
///   bearerAuth(token: token),
/// ));
/// ```
Middleware except(Object condition, Middleware middleware) {
  final check = _buildCheck(condition);

  return (Context c, Next next) async {
    if (check(c)) {
      await next();
      return;
    }
    await middleware(c, next);
  };
}

// ── Path-matching helpers ─────────────────────────────────────────────────────

typedef _Check = bool Function(Context c);

_Check _buildCheck(Object condition) {
  if (condition is _Check) {
    return condition;
  }

  if (condition is String) {
    final re = _patternToRegex(condition);
    return (c) => re.hasMatch(c.req.path);
  }

  if (condition is List) {
    final checks = condition.map<_Check>((item) {
      if (item is String) {
        final re = _patternToRegex(item);
        return (c) => re.hasMatch(c.req.path);
      }
      if (item is _Check) return item;
      throw ArgumentError('except: list items must be String or bool Function(Context)');
    }).toList();

    return (c) => checks.any((fn) => fn(c));
  }

  throw ArgumentError(
    'except: condition must be a String, List, or bool Function(Context)',
  );
}

/// Converts a path pattern like `/api/public/*` into a [RegExp].
/// `*` matches any sequence of characters (including `/`).
RegExp _patternToRegex(String pattern) {
  if (pattern == '*' || pattern == '/*') return RegExp('.*');
  final escaped = RegExp.escape(pattern).replaceAll(r'\*', '.*');
  return RegExp('^$escaped\$');
}
