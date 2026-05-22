import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:darto/darto.dart';

/// Options for JWT claim verification.
///
/// All flags default to `true` — disable them only when you need to skip a
/// specific check (e.g. `exp: false` for tokens that must not expire).
///
/// ```dart
/// app.mount('/api/*', jwt(
///   secret: env.secret,
///   verifyOptions: VerifyOptions(iss: 'my-app', nbf: true, exp: true, iat: true),
/// ));
/// ```
class VerifyOptions {
  /// Expected `iss` (issuer) claim value. Skipped when `null`.
  final String? iss;

  /// Validate the `exp` (expiration) claim when present. Defaults to `true`.
  final bool exp;

  /// Validate the `nbf` (not-before) claim when present. Defaults to `true`.
  final bool nbf;

  /// Validate that `iat` (issued-at) is not set in the future. Defaults to `true`.
  final bool iat;

  const VerifyOptions({
    this.iss,
    this.exp = true,
    this.nbf = true,
    this.iat = true,
  });
}

/// JWT authentication middleware.
///
/// Extracts a Bearer token from [headerName] (default `authorization`) or from
/// a cookie named [cookie] when provided. On success, stores the verified
/// payload in `c.get('jwtPayload')`.
///
/// Supported algorithms: `HS256` (default), `HS384`, `HS512`.
///
/// ```dart
/// // Header-based (default)
/// app.mount('/api/*', jwt(secret: env.secret));
///
/// // Cookie-based
/// app.mount('/api/*', jwt(secret: env.secret, cookie: 'access_token'));
///
/// // With full verify options
/// app.mount('/api/*', jwt(
///   secret: env.secret,
///   alg: 'HS512',
///   verifyOptions: VerifyOptions(iss: 'my-app'),
/// ));
/// ```
Middleware jwt({
  required String secret,
  String alg = 'HS256',
  String? cookie,
  String headerName = 'authorization',
  VerifyOptions? verifyOptions,
}) {
  return (Context c, Next next) async {
    String? token;

    if (cookie != null) {
      token = _parseCookie(c.req.header('cookie'), cookie);
    } else {
      final raw = c.req.header(headerName);
      if (raw != null && raw.startsWith('Bearer ')) {
        token = raw.substring(7).trim();
      }
    }

    if (token == null || token.isEmpty) {
      _unauthorizedJwt(c, 'Missing token');
      return;
    }

    final payload = _verifyJwt(
      token,
      secret,
      alg: alg,
      options: verifyOptions,
    );

    if (payload == null) {
      _unauthorizedJwt(c, 'Invalid token');
      return;
    }

    c.set('jwtPayload', payload);
    c.user = payload;

    await next();
  };
}

/// Optional JWT middleware — never rejects the request.
///
/// If a valid Bearer token is present, stores the payload in
/// `c.get('jwtPayload')` and `c.user`. Useful for routes that are public
/// but show extra content when the user is authenticated.
///
/// ```dart
/// app.mount('/feed', optionalJwt(secret: env.secret));
///
/// app.get('/feed', (c) {
///   final user = c.user; // null for anonymous, Map for authenticated
///   return c.ok({'personalised': user != null});
/// });
/// ```
Middleware optionalJwt({
  required String secret,
  String alg = 'HS256',
  String? cookie,
  String headerName = 'authorization',
  VerifyOptions? verifyOptions,
}) {
  return (Context c, Next next) async {
    String? token;

    if (cookie != null) {
      token = _parseCookie(c.req.header('cookie'), cookie);
    } else {
      final raw = c.req.header(headerName);
      if (raw != null && raw.startsWith('Bearer ')) {
        token = raw.substring(7).trim();
      }
    }

    if (token != null && token.isNotEmpty) {
      final payload = _verifyJwt(token, secret, alg: alg, options: verifyOptions);
      if (payload != null) {
        c.set('jwtPayload', payload);
        c.user = payload;
      }
    }

    await next();
  };
}

// ── Internal helpers ──────────────────────────────────────────────────────────

Map<String, dynamic>? _verifyJwt(
  String token,
  String secret, {
  String alg = 'HS256',
  VerifyOptions? options,
}) {
  final parts = token.split('.');
  if (parts.length != 3) return null;

  try {
    final hmac = _selectHmac(alg, utf8.encode(secret));
    if (hmac == null) return null;

    // Verify signature
    final data = '${parts[0]}.${parts[1]}';
    final expectedSig = _b64url(hmac.convert(utf8.encode(data)).bytes);
    if (parts[2] != expectedSig) return null;

    final payload = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(_b64urlDecode(parts[1]))) as Map,
    );

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final opts = options ?? const VerifyOptions();

    // exp — token must not be expired
    if (opts.exp) {
      if (payload['exp'] case final int exp) {
        if (now > exp) return null;
      }
    }

    // nbf — token must not be used before its valid time
    if (opts.nbf) {
      if (payload['nbf'] case final int nbf) {
        if (now < nbf) return null;
      }
    }

    // iat — issued-at must not be in the future
    if (opts.iat) {
      if (payload['iat'] case final int iat) {
        if (iat > now) return null;
      }
    }

    // iss — issuer must match when specified
    if (opts.iss != null && payload['iss'] != opts.iss) return null;

    return payload;
  } catch (_) {
    return null;
  }
}

/// Selects the HMAC variant based on [alg]. Returns `null` for unsupported algs.
Hmac? _selectHmac(String alg, List<int> key) {
  switch (alg) {
    case 'HS256':
      return Hmac(sha256, key);
    case 'HS384':
      return Hmac(sha384, key);
    case 'HS512':
      return Hmac(sha512, key);
    default:
      return null;
  }
}

/// Extracts the value of cookie [name] from a raw `Cookie` header string.
String? _parseCookie(String? cookieHeader, String name) {
  if (cookieHeader == null) return null;
  for (final part in cookieHeader.split(';')) {
    final eq = part.indexOf('=');
    if (eq == -1) continue;
    final key = part.substring(0, eq).trim();
    if (key == name) return part.substring(eq + 1).trim();
  }
  return null;
}

String _b64url(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

List<int> _b64urlDecode(String input) {
  var s = input.replaceAll('-', '+').replaceAll('_', '/');
  while (s.length % 4 != 0) s += '=';
  return base64.decode(s);
}

void _unauthorizedJwt(Context c, String message) {
  c.status(401).json({'error': message});
}
