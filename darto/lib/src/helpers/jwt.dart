import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Exception thrown when a JWT operation fails.
///
/// Thrown by [verify] when the token is malformed, the signature doesn't
/// match, or any of the standard time-based claims are violated.
class JwtException implements Exception {
  final String message;
  const JwtException(this.message);

  @override
  String toString() => 'JwtException: $message';
}

// ── JwtPayload ────────────────────────────────────────────────────────────────

/// Typed container for JWT claims.
///
/// Standard registered claims ([sub], [iss], [aud], [exp], [nbf], [iat],
/// [jti]) are available as named parameters.  Custom claims (e.g. `role`,
/// `tenantId`) are passed via [extra].
///
/// ```dart
/// final payload = JwtPayload(
///   sub: 'user123',
///   exp: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300, // 5 min
///   extra: {'role': 'admin'},
/// );
/// ```
class JwtPayload {
  /// Subject — identifies the principal this token is about.
  final String? sub;

  /// Issuer — identifies who issued the token.
  final String? iss;

  /// Audience — identifies the recipients this token is intended for.
  final String? aud;

  /// Expiration — Unix timestamp (seconds) after which the token is invalid.
  ///
  /// ```dart
  /// exp: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 60 * 5, // +5 min
  /// ```
  final int? exp;

  /// Not-before — Unix timestamp before which the token must not be used.
  final int? nbf;

  /// Issued-at — Unix timestamp when the token was issued.
  final int? iat;

  /// JWT ID — unique identifier for the token.
  final String? jti;

  /// Custom / application-specific claims.
  ///
  /// ```dart
  /// extra: {'role': 'admin', 'tenantId': 'acme'},
  /// ```
  final Map<String, dynamic> extra;

  const JwtPayload({
    this.sub,
    this.iss,
    this.aud,
    this.exp,
    this.nbf,
    this.iat,
    this.jti,
    this.extra = const {},
  });

  /// Converts this payload to a plain [Map] suitable for encoding.
  Map<String, dynamic> toMap() => {
        if (sub != null) 'sub': sub,
        if (iss != null) 'iss': iss,
        if (aud != null) 'aud': aud,
        if (exp != null) 'exp': exp,
        if (nbf != null) 'nbf': nbf,
        if (iat != null) 'iat': iat,
        if (jti != null) 'jti': jti,
        ...extra,
      };
}

// ── Public API ────────────────────────────────────────────────────────────────

/// Signs [payload] with [secret] and returns a compact JWT string.
///
/// [payload] may be a [JwtPayload] or a raw `Map<String, dynamic>`.
/// [alg] defaults to `'HS256'`; supported values: `HS256`, `HS384`, `HS512`.
///
/// ```dart
/// // Positional
/// final token = await sign(payload, secret);
///
/// // With explicit algorithm
/// final token = await sign(payload, secret, alg: 'HS512');
/// ```
Future<String> sign(
  dynamic payload,
  String secret, {
  String alg = 'HS256',
}) async {
  final Map<String, dynamic> claims = switch (payload) {
    JwtPayload p => p.toMap(),
    Map<String, dynamic> m => m,
    _ => throw ArgumentError(
        'payload must be a JwtPayload or Map<String, dynamic>'),
  };

  final hmac = _hmacFor(alg, utf8.encode(secret));
  if (hmac == null) throw ArgumentError('Unsupported algorithm: $alg');

  final header = _b64url(utf8.encode(jsonEncode({'alg': alg, 'typ': 'JWT'})));
  final body = _b64url(utf8.encode(jsonEncode(claims)));
  final sig = _b64url(hmac.convert(utf8.encode('$header.$body')).bytes);

  return '$header.$body.$sig';
}

/// Verifies [token] against [secret] using [alg], validates standard
/// time-based claims (`exp`, `nbf`, `iat`), and returns the decoded payload.
///
/// Throws [JwtException] when the signature is invalid, the token is expired,
/// or any other claim check fails.
///
/// ```dart
/// try {
///   final payload = await verify(token, secret);
///   print(payload['sub']);
/// } on JwtException catch (e) {
///   print(e.message); // 'Token expired', 'Invalid signature', etc.
/// }
/// ```
Future<Map<String, dynamic>> verify(
  String token,
  String secret, [
  String alg = 'HS256',
]) async {
  final parts = token.split('.');
  if (parts.length != 3) throw const JwtException('Malformed token');

  final hmac = _hmacFor(alg, utf8.encode(secret));
  if (hmac == null) throw JwtException('Unsupported algorithm: $alg');

  final expected =
      _b64url(hmac.convert(utf8.encode('${parts[0]}.${parts[1]}')).bytes);
  if (parts[2] != expected) throw const JwtException('Invalid signature');

  final Map<String, dynamic> claims;
  try {
    claims = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(_b64urlDecode(parts[1]))) as Map,
    );
  } catch (_) {
    throw const JwtException('Malformed payload');
  }

  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  if (claims['exp'] case final int exp) {
    if (now > exp) throw const JwtException('Token expired');
  }

  if (claims['nbf'] case final int nbf) {
    if (now < nbf) throw const JwtException('Token not yet valid');
  }

  if (claims['iat'] case final int iat) {
    if (iat > now) throw const JwtException('Token issued in the future');
  }

  return claims;
}

/// Decodes [token] **without** verifying the signature or validating claims.
///
/// Returns `[header, payload]` as a two-element list.  Throws [JwtException]
/// when the token is structurally malformed.
///
/// ```dart
/// final [header, payload] = decode(token);
/// print(header['alg']);   // 'HS256'
/// print(payload['sub']);  // 'user123'
/// ```
List<Map<String, dynamic>> decode(String token) {
  final parts = token.split('.');
  if (parts.length != 3) throw const JwtException('Malformed token');

  try {
    final header = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(_b64urlDecode(parts[0]))) as Map,
    );
    final payload = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(_b64urlDecode(parts[1]))) as Map,
    );
    return [header, payload];
  } catch (_) {
    throw const JwtException('Malformed token');
  }
}

// ── Internals ─────────────────────────────────────────────────────────────────

Hmac? _hmacFor(String alg, List<int> key) => switch (alg) {
      'HS256' => Hmac(sha256, key),
      'HS384' => Hmac(sha384, key),
      'HS512' => Hmac(sha512, key),
      _ => null,
    };

String _b64url(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

List<int> _b64urlDecode(String input) {
  var s = input.replaceAll('-', '+').replaceAll('_', '/');
  while (s.length % 4 != 0) {
    s += '=';
  }
  return base64.decode(s);
}
