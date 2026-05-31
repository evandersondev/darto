import 'package:darto/darto.dart';
import 'package:darto/session.dart';
import 'package:darto_auth/darto_auth.dart';
import 'package:darto_test/darto_test.dart';
import 'package:test/test.dart';

Darto buildApp() {
  final app = Darto();
  app.use(sessionMiddleware(secret: 'at-least-32-chars-long-secret!!!'));

  app.post('/login', [], (c) async {
    await signIn(c, {'id': '42', 'role': 'admin'});
    return c.ok({'ok': true});
  });
  app.post('/logout', [], (c) {
    signOut(c);
    return c.noContent();
  });
  app.get('/me', [authGuard()], (c) => c.ok(authUser(c)));
  return app;
}

void main() {
  group('session auth', () {
    test('authGuard blocks unauthenticated requests with 401', () async {
      final client = await TestClient.create(buildApp());
      final res = await client.get('/me');
      expect(res.statusCode, equals(401));
      await client.close();
    });

    test('signIn → authGuard allows; /me returns the user', () async {
      final client = await TestClient.create(buildApp());

      final login = await client.post('/login');
      final cookie = login.cookie('darto.session');
      expect(cookie, isNotNull);

      final me = await client.get('/me', headers: {'cookie': 'darto.session=$cookie'});
      expect(me.statusCode, equals(200));
      expect(me.json['id'], equals('42'));

      await client.close();
    });
  });
}
