import 'package:darto/darto.dart';

const _kDefaultMethods = ['GET', 'HEAD', 'PUT', 'POST', 'DELETE', 'PATCH'];
const _kDefaultHeaders = ['Content-Type', 'Authorization'];

/// CORS middleware.
///
/// Sets the appropriate `Access-Control-*` headers and handles preflight
/// (`OPTIONS`) requests automatically.
///
/// ```dart
/// // Permissive default (origin: *)
/// app.mount('/api/*', cors());
///
/// // Static configuration
/// app.mount('/api/*', cors(
///   origin: 'https://example.com',
///   allowHeaders: ['X-Custom-Header', 'Authorization'],
///   allowMethods: ['GET', 'POST', 'DELETE'],
///   exposeHeaders: ['Content-Length'],
///   maxAge: 600,
///   credentials: true,
/// ));
///
/// // Dynamic origin
/// app.mount('/api/*', cors(
///   originFn: (origin) =>
///       origin.endsWith('.example.com') ? origin : '*',
/// ));
///
/// // Dynamic methods per origin
/// app.mount('/api/*', cors(
///   allowMethodsFn: (origin, c) =>
///       origin == 'https://admin.example.com'
///           ? ['GET', 'POST', 'PATCH', 'DELETE']
///           : ['GET'],
/// ));
/// ```
Middleware cors({
  String origin = '*',
  List<String>? allowHeaders,
  List<String>? allowMethods,
  List<String>? exposeHeaders,
  int? maxAge,
  bool credentials = false,
  String Function(String origin)? originFn,
  List<String> Function(String origin, Context c)? allowMethodsFn,
}) {
  return (Context c, Next next) async {
    final requestOrigin = c.req.header('origin') ?? '';

    // ── Resolve allowed origin ─────────────────────────────────────────────
    final allowedOrigin =
        originFn != null ? originFn(requestOrigin) : origin;

    // ── Common headers (set on every response) ─────────────────────────────
    c.header('Access-Control-Allow-Origin', allowedOrigin);

    if (credentials) {
      c.header('Access-Control-Allow-Credentials', 'true');
    }

    if (exposeHeaders != null && exposeHeaders.isNotEmpty) {
      c.header('Access-Control-Expose-Headers', exposeHeaders.join(', '));
    }

    // Vary so caches don't serve the wrong origin's response
    if (originFn != null || allowMethodsFn != null) {
      c.header('Vary', 'Origin');
    }

    // ── Preflight ──────────────────────────────────────────────────────────
    if (c.req.method == 'OPTIONS') {
      final methods = allowMethodsFn != null
          ? allowMethodsFn(requestOrigin, c)
          : (allowMethods ?? _kDefaultMethods);

      c.header('Access-Control-Allow-Methods', methods.join(', '));
      c.header(
        'Access-Control-Allow-Headers',
        (allowHeaders ?? _kDefaultHeaders).join(', '),
      );

      if (maxAge != null) {
        c.header('Access-Control-Max-Age', '$maxAge');
      }

      c.noContent();
      return;
    }

    await next();
  };
}
