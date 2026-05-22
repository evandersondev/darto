import 'package:darto/darto.dart';

const _kSafeMethods = {'GET', 'HEAD', 'OPTIONS'};

/// CSRF protection middleware.
///
/// Blocks state-mutating requests (`POST`, `PUT`, `PATCH`, `DELETE`, …) whose
/// origin does not match the configured allow-list. Safe methods
/// (`GET`, `HEAD`, `OPTIONS`) are always passed through.
///
/// **Origin-based (default)**
///
/// When no options are provided, the `Origin` header is compared against the
/// request `Host`. Requests without an `Origin` header (e.g. same-origin
/// server-to-server calls) are also passed.
///
/// ```dart
/// app.use(csrf());
/// ```
///
/// **Static origin**
/// ```dart
/// app.use(csrf(origin: 'https://myapp.example.com'));
/// ```
///
/// **Multiple origins**
/// ```dart
/// app.use(csrf(origins: [
///   'https://myapp.example.com',
///   'https://dev.myapp.example.com',
/// ]));
/// ```
///
/// **`Sec-Fetch-Site` header**
///
/// Modern browsers send this header on every request. Use it as a lightweight
/// alternative to origin matching (supports a single value or a list).
///
/// ```dart
/// app.use(csrf(secFetchSite: 'same-origin'));
/// app.use(csrf(secFetchSite: ['same-origin', 'none']));
/// ```
///
/// **Custom function**
/// ```dart
/// app.use(csrf(
///   originFn: (origin) =>
///       RegExp(r'https://(\w+\.)?myapp\.example\.com$').hasMatch(origin),
/// ));
/// ```
Middleware csrf({
  String? origin,
  List<String>? origins,
  Object? secFetchSite, // String | List<String>
  bool Function(String origin)? originFn,
}) {
  return (Context c, Next next) async {
    // Safe HTTP methods are always allowed
    if (_kSafeMethods.contains(c.req.method)) {
      await next();
      return;
    }

    // ── Sec-Fetch-Site check (takes priority when provided) ────────────────
    if (secFetchSite != null) {
      final site = c.req.header('sec-fetch-site') ?? '';
      final allowed = secFetchSite is List
          ? secFetchSite.cast<String>()
          : [secFetchSite as String];

      if (!allowed.contains(site)) {
        c.forbidden({'error': 'Forbidden'});
        return;
      }

      await next();
      return;
    }

    // ── Origin-based check ─────────────────────────────────────────────────
    final requestOrigin = c.req.header('origin') ?? '';

    final bool allowed;

    if (originFn != null) {
      allowed = originFn(requestOrigin);
    } else if (origins != null) {
      allowed = origins.contains(requestOrigin);
    } else if (origin != null) {
      allowed = requestOrigin == origin;
    } else {
      // Default: allow when Origin is absent or matches the request Host.
      if (requestOrigin.isEmpty) {
        allowed = true;
      } else {
        final host = (c.req.header('host') ?? '').split(':').first;
        final uri = Uri.tryParse(requestOrigin);
        allowed = uri != null && uri.host == host;
      }
    }

    if (!allowed) {
      c.forbidden({'error': 'Forbidden'});
      return;
    }

    await next();
  };
}
