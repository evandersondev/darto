import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Random url-safe string for the PKCE `code_verifier` — between 43 and 128
/// characters per RFC 7636.
String pkceVerifier([int length = 64]) {
  if (length < 43 || length > 128) {
    throw ArgumentError('PKCE verifier length must be 43..128');
  }
  final rng = Random.secure();
  final bytes = List<int>.generate(length, (_) => rng.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '').substring(0, length);
}

/// SHA-256 of [verifier], base64url-encoded without padding — the
/// `code_challenge` matching the `S256` method.
String pkceChallenge(String verifier) {
  final hash = sha256.convert(utf8.encode(verifier)).bytes;
  return base64UrlEncode(hash).replaceAll('=', '');
}

/// Cryptographically random hex string — used for the OAuth `state` parameter
/// (CSRF protection) and OIDC `nonce`.
String randomToken([int bytes = 32]) {
  final rng = Random.secure();
  final buf = List<int>.generate(bytes, (_) => rng.nextInt(256));
  return buf.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
