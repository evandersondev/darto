import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Password hashing using **PBKDF2-HMAC-SHA256** — no native dependencies.
///
/// Hashes are self-describing: `pbkdf2-sha256$<iterations>$<saltB64>$<keyB64>`,
/// so [verifyPassword] reads the parameters back from the stored string.
///
/// ```dart
/// final hash = hashPassword('s3cret');     // store this
/// final ok   = verifyPassword('s3cret', hash); // true
/// ```
class PasswordHasher {
  /// PBKDF2 iteration count. Higher = slower to brute-force.
  final int iterations;

  /// Random salt length in bytes.
  final int saltLength;

  const PasswordHasher({this.iterations = 100000, this.saltLength = 16});

  static final _rnd = Random.secure();

  /// Hashes [password] into a self-describing string.
  String hash(String password) {
    final salt = List<int>.generate(saltLength, (_) => _rnd.nextInt(256));
    final key = _pbkdf2(utf8.encode(password), salt, iterations);
    return 'pbkdf2-sha256\$$iterations\$${base64.encode(salt)}\$${base64.encode(key)}';
  }

  /// Verifies [password] against a [hash] produced by [hash]. Returns `false`
  /// for malformed hashes (never throws).
  bool verify(String password, String hash) {
    final parts = hash.split(r'$');
    if (parts.length != 4 || parts[0] != 'pbkdf2-sha256') return false;
    final iter = int.tryParse(parts[1]);
    if (iter == null) return false;
    final List<int> salt;
    final List<int> expected;
    try {
      salt = base64.decode(parts[2]);
      expected = base64.decode(parts[3]);
    } catch (_) {
      return false;
    }
    final actual = _pbkdf2(utf8.encode(password), salt, iter);
    return _constantTimeEquals(actual, expected);
  }

  /// PBKDF2-HMAC-SHA256 producing a single 32-byte block (dkLen = hLen).
  static List<int> _pbkdf2(List<int> password, List<int> salt, int iterations) {
    final hmac = Hmac(sha256, password);
    // U1 = HMAC(password, salt || INT_32_BE(1))
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var k = 0; k < result.length; k++) {
        result[k] ^= u[k];
      }
    }
    return result;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

const _defaultHasher = PasswordHasher();

/// Hashes [password] with the default [PasswordHasher].
String hashPassword(String password) => _defaultHasher.hash(password);

/// Verifies [password] against [hash] with the default [PasswordHasher].
bool verifyPassword(String password, String hash) =>
    _defaultHasher.verify(password, hash);
