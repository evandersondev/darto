import 'package:darto/darto.dart';
import 'package:test/test.dart';

void main() {
  group('Router', () {
    test('can be instantiated and used standalone', () {
      final router = Router();
      router.get('/hello', [], (c) => c.ok('hello'));
      expect(router, isNotNull);
    });
  });
}
