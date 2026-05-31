import 'package:darto_auth/darto_auth.dart';
import 'package:test/test.dart';

void main() {
  group('password hashing', () {
    test('hash then verify succeeds', () {
      final hash = hashPassword('s3cret-pass');
      expect(verifyPassword('s3cret-pass', hash), isTrue);
    });

    test('wrong password fails', () {
      final hash = hashPassword('s3cret-pass');
      expect(verifyPassword('wrong', hash), isFalse);
    });

    test('hashes are self-describing and salted (differ per call)', () {
      final a = hashPassword('same');
      final b = hashPassword('same');
      expect(a, startsWith('pbkdf2-sha256\$'));
      expect(a, isNot(equals(b))); // random salt
      expect(verifyPassword('same', a), isTrue);
      expect(verifyPassword('same', b), isTrue);
    });

    test('malformed hash returns false (never throws)', () {
      expect(verifyPassword('x', 'not-a-hash'), isFalse);
      expect(verifyPassword('x', r'pbkdf2-sha256$bad$$'), isFalse);
    });

    test('custom iterations round-trip', () {
      const hasher = PasswordHasher(iterations: 5000);
      final hash = hasher.hash('pw');
      expect(hasher.verify('pw', hash), isTrue);
      // The default hasher reads iterations from the string, so it verifies too.
      expect(verifyPassword('pw', hash), isTrue);
    });
  });
}
