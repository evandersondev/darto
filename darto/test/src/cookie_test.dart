import 'dart:convert';

import 'package:darto/cookie.dart';
import 'package:darto/session.dart';
import 'package:test/test.dart';

import '../support/harness.dart';

void main() {
  group('cookie helper', () {
    test('reads a cookie sent by the client (from the request, not response)',
        () async {
      await withServer((app) {
        app.get('/read', [], (c) => c.text(getCookie(c, 'foo') ?? 'none'));
      }, (port) async {
        final res = await request(port, '/read', cookie: 'foo=bar');
        expect(await bodyOf(res), equals('bar'));
      });
    });

    test('parses values containing "=" (base64url padding)', () async {
      await withServer((app) {
        app.get('/read', [], (c) => c.text(getCookie(c, 'data') ?? 'none'));
      }, (port) async {
        final res = await request(port, '/read', cookie: 'data=YWJj==');
        expect(await bodyOf(res), equals('YWJj=='));
      });
    });

    test('setting multiple cookies emits multiple Set-Cookie headers',
        () async {
      await withServer((app) {
        app.get('/set', [], (c) {
          setCookie(c, 'a', '1');
          setCookie(c, 'b', '2');
          return c.ok({});
        });
      }, (port) async {
        final res = await request(port, '/set');
        await bodyOf(res);
        final names = res.cookies.map((c) => c.name).toList();
        expect(names, containsAll(['a', 'b']));
        expect(names.length, equals(2));
      });
    });

    test('signed cookie round-trips and rejects tampering', () async {
      const secret = 'super-secret-key';
      await withServer((app) {
        app.get('/sign', [], (c) async {
          await setSignedCookie(c, 's', 'hello', secret);
          return c.ok({});
        });
        app.get('/verify', [],
            (c) async => c.text(await getSignedCookie(c, secret, 's') ?? 'invalid'));
      }, (port) async {
        // Issue the signed cookie.
        final signRes = await request(port, '/sign');
        await bodyOf(signRes);
        final signed = signRes.cookies.firstWhere((c) => c.name == 's').value;

        // Send it back — should verify to the original value.
        final ok = await request(port, '/verify', cookie: 's=$signed');
        expect(await bodyOf(ok), equals('hello'));

        // Tampered value should be rejected.
        final bad = await request(port, '/verify', cookie: 's=hacked.$signed');
        expect(await bodyOf(bad), equals('invalid'));
      });
    });
  });

  group('session middleware', () {
    test('login sets a session cookie that /me reads back on next request',
        () async {
      await withServer((app) {
        app.use(sessionMiddleware(secret: 'at-least-32-chars-long-secret!!!'));
        app.get('/login', [], (c) async {
          await sessionContext(c).update({'userId': '42'});
          return c.ok({'ok': true});
        });
        app.get('/me', [], (c) {
          final data = sessionContext(c).get();
          if (data == null) return c.unauthorized({'error': 'no session'});
          return c.ok(data);
        });
      }, (port) async {
        final login = await request(port, '/login');
        await bodyOf(login);
        final session =
            login.cookies.firstWhere((c) => c.name == 'darto.session').value;

        final me = await request(port, '/me', cookie: 'darto.session=$session');
        final data = jsonDecode(await bodyOf(me)) as Map<String, dynamic>;
        expect(data['userId'], equals('42'));
      });
    });

    test('get() returns null (not a 500) when there is no session', () async {
      await withServer((app) {
        app.use(sessionMiddleware(secret: 'at-least-32-chars-long-secret!!!'));
        app.get('/me', [], (c) {
          final data = sessionContext(c).get();
          return data == null ? c.unauthorized({'error': 'no session'}) : c.ok(data);
        });
      }, (port) async {
        final res = await request(port, '/me'); // no cookie
        await bodyOf(res);
        expect(res.statusCode, equals(401));
      });
    });
  });
}
