import 'dart:async';

import 'package:darto/darto.dart';
import 'package:test/test.dart';

import '../support/harness.dart';

/// Boots [app] (allowing `strict` to be set by the caller) on an ephemeral
/// port, runs [body], then stops it. Mirrors [withServer] but lets the caller
/// construct the app — needed for strict-mode coverage.
Future<void> withApp(
  Darto app,
  Future<void> Function(int port) body,
) async {
  final ready = Completer<void>();
  unawaited(
      app.serve(port: 0, shutdownSignals: false, onListen: ready.complete));
  await ready.future;
  try {
    await body(app.port!);
  } finally {
    await app.stop();
  }
}

void main() {
  group('Router', () {
    test('can be instantiated and used standalone', () {
      final router = Router();
      router.get('/hello', [], (c) => c.ok('hello'));
      expect(router, isNotNull);
    });
  });

  group('router matching', () {
    test('static route matches exactly and tolerates a trailing slash', () {
      return withServer((app) {
        app.get('/users', [], (c) => c.text('users'));
      }, (port) async {
        expect(await bodyOf(await request(port, '/users')), 'users');
        // non-strict: one optional trailing slash matches the same route
        expect(await bodyOf(await request(port, '/users/')), 'users');
      });
    });

    test('static route does not match a longer path', () {
      return withServer((app) {
        app.get('/users', [], (c) => c.text('users'));
      }, (port) async {
        final res = await request(port, '/users/extra');
        expect(res.statusCode, 404);
      });
    });

    test('overlapping static routes resolve to the right one', () {
      return withServer((app) {
        app.get('/a', [], (c) => c.text('a'));
        app.get('/ab', [], (c) => c.text('ab'));
        app.get('/abc', [], (c) => c.text('abc'));
      }, (port) async {
        expect(await bodyOf(await request(port, '/a')), 'a');
        expect(await bodyOf(await request(port, '/ab')), 'ab');
        expect(await bodyOf(await request(port, '/abc')), 'abc');
      });
    });

    test('method mismatch on a static route falls through to 404', () {
      return withServer((app) {
        app.get('/users', [], (c) => c.text('users'));
      }, (port) async {
        final res = await request(port, '/users', method: 'POST');
        expect(res.statusCode, 404);
      });
    });

    test('two methods on the same static path dispatch independently', () {
      return withServer((app) {
        app.get('/users', [], (c) => c.text('get'));
        app.post('/users', [], (c) => c.text('post'));
      }, (port) async {
        expect(await bodyOf(await request(port, '/users')), 'get');
        expect(
          await bodyOf(await request(port, '/users', method: 'POST')),
          'post',
        );
      });
    });

    test('named param route extracts the value', () {
      return withServer((app) {
        app.get('/users/:id', [], (c) => c.text('id=${c.req.param('id')}'));
      }, (port) async {
        expect(await bodyOf(await request(port, '/users/42')), 'id=42');
      });
    });

    test('optional param route matches with and without the segment', () {
      return withServer((app) {
        app.get(
            '/posts/:id?', [], (c) => c.text('id=${c.req.param('id') ?? '-'}'));
      }, (port) async {
        expect(await bodyOf(await request(port, '/posts')), 'id=-');
        expect(await bodyOf(await request(port, '/posts/7')), 'id=7');
      });
    });

    test('regex-constrained param only matches the pattern', () {
      return withServer((app) {
        app.get(
            '/items/:id(\\d+)', [], (c) => c.text('item=${c.req.param('id')}'));
      }, (port) async {
        expect(await bodyOf(await request(port, '/items/123')), 'item=123');
        expect((await request(port, '/items/abc')).statusCode, 404);
      });
    });

    test('named wildcard captures the remainder', () {
      return withServer((app) {
        app.get(
            '/files/*path', [], (c) => c.text('path=${c.req.param('path')}'));
      }, (port) async {
        expect(
          await bodyOf(await request(port, '/files/a/b/c.txt')),
          'path=a/b/c.txt',
        );
      });
    });

    test('dotted static path matches (kept on the regex path)', () {
      return withServer((app) {
        app.get('/sitemap.xml', [], (c) => c.text('map'));
      }, (port) async {
        expect(await bodyOf(await request(port, '/sitemap.xml')), 'map');
      });
    });

    test('mount middleware runs for matching prefix only', () {
      return withServer((app) {
        app.mount('/api/*', (c, next) {
          c.res.set('X-Api', 'yes');
          return next();
        });
        app.get('/api/ping', [], (c) => c.text('pong'));
        app.get('/health', [], (c) => c.text('ok'));
      }, (port) async {
        final api = await request(port, '/api/ping');
        expect(await bodyOf(api), 'pong');
        expect(api.headers.value('X-Api'), 'yes');

        final health = await request(port, '/health');
        expect(await bodyOf(health), 'ok');
        expect(health.headers.value('X-Api'), isNull);
      });
    });

    test('global middleware runs for every request', () {
      return withServer((app) {
        app.use((c, next) {
          c.res.set('X-Global', '1');
          return next();
        });
        app.get('/x', [], (c) => c.text('x'));
      }, (port) async {
        final res = await request(port, '/x');
        expect(res.headers.value('X-Global'), '1');
      });
    });

    test('unknown path returns 404', () {
      return withServer((app) {
        app.get('/known', [], (c) => c.text('known'));
      }, (port) async {
        expect((await request(port, '/nope')).statusCode, 404);
      });
    });
  });

  group('router matching (strict mode)', () {
    test('strict static route rejects a trailing slash', () {
      return withApp(
          Darto(strict: true)..get('/users', [], (c) => c.text('u')),
          (port) async {
        expect(await bodyOf(await request(port, '/users')), 'u');
        expect((await request(port, '/users/')).statusCode, 404);
      });
    });
  });
}
