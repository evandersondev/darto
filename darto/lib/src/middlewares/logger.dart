import 'dart:io';

import 'package:darto/darto.dart';

/// Signature for a custom print function used by [logger].
///
/// The middleware calls [fn] with a single pre-formatted string.
/// The optional [rest] parameter lets you reuse the same function
/// for custom log lines inside route handlers.
///
/// ```dart
/// final log = (String message, [List<String>? rest]) {
///   if (rest != null && rest.isNotEmpty) {
///     print('$message ${rest.join(' ')}');
///   } else {
///     print(message);
///   }
/// };
///
/// app.use(logger(log));
///
/// app.post('/blog', (Context c) async {
///   final blog = await c.body();
///   log('Blog saved:', ['Path: ${blog['url']},', 'ID: ${blog['id']}']);
///   // --> POST /blog
///   // Blog saved: Path: /blog/example, ID: 1
///   // <-- POST /blog 201 4ms
///   return c.created(blog);
/// });
/// ```
typedef PrintFn = void Function(String message, [List<String>? rest]);

/// HTTP request/response logger middleware, modeled after HonoJS.
///
/// Prints an incoming line before the handler and an outgoing line with a
/// colored status code and elapsed time after it. Uses `xxx` as prefix when
/// the handler throws.
///
/// Respects the `NO_COLOR` environment variable (https://no-color.org).
///
/// ```dart
/// app.use(logger());
/// ```
///
/// Output:
/// ```
/// --> GET /users
/// <-- GET /users 200 4ms
/// ```
///
/// Custom printer:
/// ```dart
/// app.use(logger((msg, [_]) => myLogSystem.info(msg)));
/// ```
Middleware logger([PrintFn? fn]) {
  final log = fn ?? _defaultPrint;

  return (Context c, Next next) async {
    final method = c.req.method;
    final path = c.req.path;

    _emit(log, _Prefix.incoming, method, path);

    final start = DateTime.now();

    try {
      await next();
    } catch (_) {
      _emit(log, _Prefix.error, method, path);
      rethrow;
    }

    _emit(
      log,
      _Prefix.outgoing,
      method,
      path,
      status: c.statusCode,
      elapsed: _elapsed(start),
    );
  };
}

// ── Internals ─────────────────────────────────────────────────────────────────

enum _Prefix {
  incoming('-->'),
  outgoing('<--'),
  error('xxx');

  final String value;
  const _Prefix(this.value);
}

void _emit(
  PrintFn fn,
  _Prefix prefix,
  String method,
  String path, {
  int status = 0,
  String? elapsed,
}) {
  final out = prefix == _Prefix.incoming
      ? '${prefix.value} $method $path'
      : '${prefix.value} $method $path ${_colorStatus(status)} $elapsed';
  fn(out);
}

String _colorStatus(int status) {
  if (_isNoColor()) return '$status';
  return switch (status ~/ 100) {
    5 => '\x1b[31m$status\x1b[0m', // red
    4 => '\x1b[33m$status\x1b[0m', // yellow
    3 => '\x1b[36m$status\x1b[0m', // cyan
    2 => '\x1b[32m$status\x1b[0m', // green
    _ => '$status',
  };
}

bool _isNoColor() {
  final v = Platform.environment['NO_COLOR'];
  return v != null && v.isNotEmpty;
}

String _elapsed(DateTime start) {
  final ms = DateTime.now().difference(start).inMilliseconds;
  return ms < 1000 ? '${ms}ms' : '${(ms / 1000).round()}s';
}

void _defaultPrint(String message, [List<String>? rest]) {
  // ignore: avoid_print
  if (rest != null && rest.isNotEmpty) {
    print('$message ${rest.join(' ')}');
  } else {
    print(message);
  }
}
