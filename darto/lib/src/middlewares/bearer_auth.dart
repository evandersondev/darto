import 'dart:async';

import 'package:darto/src/core/darto_base.dart';

/// Options for customizing an individual error response in [bearerAuth].
///
/// [message] receives the [Context] and returns the response body.
/// Return a `String` for plain-text or a `Map` for JSON.
/// When `null`, the middleware uses its built-in default.
///
/// [wwwAuthenticate] overrides the `WWW-Authenticate` header sent with the
/// error response. When `null`, a standards-compliant default is used.
///
/// ```dart
/// BearerAuthErrorOptions(
///   message: (c) => {'error': 'Token missing', 'path': c.req.path},
///   wwwAuthenticate: 'Bearer realm="myapp"',
/// )
/// ```
class BearerAuthErrorOptions {
  final FutureOr<dynamic> Function(Context c)? message;
  final String? wwwAuthenticate;

  const BearerAuthErrorOptions({this.message, this.wwwAuthenticate});
}

/// Bearer token authentication middleware.
///
/// Validates the `Authorization: Bearer <token>` header (or a custom header /
/// prefix). Supply either [token] (one static token or a list) or a
/// [verifyToken] callback — not both.
///
/// **Three distinct error cases:**
/// - No `Authorization` header → `401 Unauthorized`
/// - Malformed header (bad format/chars) → `400 Bad Request`
/// - Valid format but token rejected → `401 Unauthorized`
///
/// Each case is independently customisable via [noAuthenticationHeader],
/// [invalidAuthenticationHeader], and [invalidToken].
///
/// ```dart
/// // Static token
/// app.mount('/api/*', bearerAuth(token: 'my-secret'));
///
/// // Multiple valid tokens
/// app.mount('/api/*', bearerAuth(token: ['token-a', 'token-b']));
///
/// // Custom verification
/// app.mount('/api/*', bearerAuth(
///   verifyToken: (token, c) => token == env.secret,
/// ));
///
/// // Custom prefix / header
/// app.mount('/api/*', bearerAuth(
///   token: 'secret',
///   prefix: 'Token',
///   headerName: 'x-api-key',
/// ));
///
/// // Custom error responses
/// app.mount('/api/*', bearerAuth(
///   token: 'secret',
///   noAuthenticationHeader: BearerAuthErrorOptions(
///     message: (c) => {'error': 'No token provided'},
///   ),
///   invalidAuthenticationHeader: BearerAuthErrorOptions(
///     message: (c) => {'error': 'Malformed token'},
///   ),
///   invalidToken: BearerAuthErrorOptions(
///     message: (c) => {'error': 'Token rejected'},
///   ),
/// ));
/// ```
Middleware bearerAuth({
  Object? token, // String | List<String>
  FutureOr<bool> Function(String token, Context c)? verifyToken,
  String prefix = 'Bearer',
  String headerName = 'authorization',
  String? Function(String input)? hashFunction,
  BearerAuthErrorOptions? noAuthenticationHeader,
  BearerAuthErrorOptions? invalidAuthenticationHeader,
  BearerAuthErrorOptions? invalidToken,
}) {
  assert(
    token != null || verifyToken != null,
    'bearerAuth requires either "token" or "verifyToken"',
  );

  final wwwPrefix = prefix.isEmpty ? '' : '$prefix ';

  return (Context c, Next next) async {
    final rawHeader = c.req.header(headerName);

    // ── 1. No Authorization header ────────────────────────────────────────────
    if (rawHeader == null) {
      await _respond(
        c,
        status: 401,
        wwwAuthenticate:
            noAuthenticationHeader?.wwwAuthenticate ?? '${wwwPrefix}realm=""',
        messageOption: noAuthenticationHeader?.message,
        defaultMessage: 'Unauthorized',
      );
      return;
    }

    // ── 2. Malformed / invalid header format ──────────────────────────────────
    String? tokenValue;

    if (prefix.isEmpty) {
      tokenValue = rawHeader;
    } else if (rawHeader.toLowerCase().startsWith(prefix.toLowerCase()) &&
        rawHeader.length > prefix.length &&
        rawHeader[prefix.length] == ' ') {
      tokenValue = rawHeader.substring(prefix.length + 1).trimLeft();
    }

    final validChars = RegExp(r'^[A-Za-z0-9._~+/\-]+=*$');

    if (tokenValue == null ||
        tokenValue.isEmpty ||
        !validChars.hasMatch(tokenValue)) {
      await _respond(
        c,
        status: 400,
        wwwAuthenticate: invalidAuthenticationHeader?.wwwAuthenticate ??
            '${wwwPrefix}error="invalid_request"',
        messageOption: invalidAuthenticationHeader?.message,
        defaultMessage: 'Bad Request',
      );
      return;
    }

    // ── 3. Validate token ─────────────────────────────────────────────────────
    bool valid = false;

    if (verifyToken != null) {
      valid = await verifyToken(tokenValue, c);
    } else if (token is String) {
      valid = await _timingSafeEqual(token, tokenValue, hashFunction);
    } else if (token is List) {
      for (final t in token.cast<String>()) {
        if (await _timingSafeEqual(t, tokenValue, hashFunction)) {
          valid = true;
          break;
        }
      }
    }

    if (!valid) {
      await _respond(
        c,
        status: 401,
        wwwAuthenticate: invalidToken?.wwwAuthenticate ??
            '${wwwPrefix}error="invalid_token"',
        messageOption: invalidToken?.message,
        defaultMessage: 'Unauthorized',
      );
      return;
    }

    await next();
  };
}

// ── Internals ─────────────────────────────────────────────────────────────────

Future<void> _respond(
  Context c, {
  required int status,
  required String wwwAuthenticate,
  FutureOr<dynamic> Function(Context c)? messageOption,
  required String defaultMessage,
}) async {
  c.header('WWW-Authenticate', wwwAuthenticate);
  final body = messageOption != null ? await messageOption(c) : defaultMessage;
  if (body is String) {
    c.status(status).text(body);
  } else {
    c.status(status).json(body);
  }
}

/// Constant-time token comparison.
///
/// When [hashFn] is provided, both tokens are hashed before comparison to add
/// an extra layer of protection. The XOR loop prevents early-exit timing leaks.
Future<bool> _timingSafeEqual(
  String a,
  String b,
  String? Function(String)? hashFn,
) async {
  final ha = hashFn != null ? (hashFn(a) ?? '') : a;
  final hb = hashFn != null ? (hashFn(b) ?? '') : b;

  // Run the full XOR loop regardless of length to avoid timing leaks.
  final len = ha.length > hb.length ? ha.length : hb.length;
  var diff = ha.length ^ hb.length; // non-zero if lengths differ
  for (var i = 0; i < len; i++) {
    final ca = i < ha.length ? ha.codeUnitAt(i) : 0;
    final cb = i < hb.length ? hb.codeUnitAt(i) : 0;
    diff |= ca ^ cb;
  }
  return diff == 0;
}
