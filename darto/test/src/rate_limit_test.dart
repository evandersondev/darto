import 'dart:async';

import 'package:darto/rate_limit.dart';
import 'package:test/test.dart';

import '../support/harness.dart';

void main() {
  group('rateLimit', () {
    test('allows up to max requests then returns 429', () async {
      await withServer((app) {
        app.use(rateLimit(max: 3));
        app.get('/', [], (c) => c.text('ok'));
      }, (port) async {
        for (var i = 0; i < 3; i++) {
          final res = await request(port, '/');
          await bodyOf(res);
          expect(res.statusCode, equals(200));
        }
        final blocked = await request(port, '/');
        await bodyOf(blocked);
        expect(blocked.statusCode, equals(429));
        expect(blocked.headers.value('retry-after'), isNotNull);
        expect(blocked.headers.value('ratelimit-remaining'), equals('0'));
      });
    });

    test('emits RateLimit-* headers', () async {
      await withServer((app) {
        app.use(rateLimit(max: 5));
        app.get('/', [], (c) => c.text('ok'));
      }, (port) async {
        final res = await request(port, '/');
        await bodyOf(res);
        expect(res.headers.value('ratelimit-limit'), equals('5'));
        expect(res.headers.value('ratelimit-remaining'), equals('4'));
        expect(res.headers.value('ratelimit-reset'), isNotNull);
      });
    });

    test('tracks separate keys independently', () async {
      await withServer((app) {
        app.use(rateLimit(
          max: 1,
          keyGenerator: (c) => c.req.header('x-key') ?? 'default',
        ));
        app.get('/', [], (c) => c.text('ok'));
      }, (port) async {
        final a1 = await request(port, '/', headers: {'x-key': 'a'});
        await bodyOf(a1);
        expect(a1.statusCode, equals(200));

        final a2 = await request(port, '/', headers: {'x-key': 'a'});
        await bodyOf(a2);
        expect(a2.statusCode, equals(429)); // key "a" exhausted

        final b1 = await request(port, '/', headers: {'x-key': 'b'});
        await bodyOf(b1);
        expect(b1.statusCode, equals(200)); // key "b" independent
      });
    });

    test('window resets after it elapses', () async {
      await withServer((app) {
        app.use(rateLimit(max: 1, window: const Duration(milliseconds: 300)));
        app.get('/', [], (c) => c.text('ok'));
      }, (port) async {
        final first = await request(port, '/');
        await bodyOf(first);
        expect(first.statusCode, equals(200));

        final blocked = await request(port, '/');
        await bodyOf(blocked);
        expect(blocked.statusCode, equals(429));

        await Future.delayed(const Duration(milliseconds: 350));

        final after = await request(port, '/');
        await bodyOf(after);
        expect(after.statusCode, equals(200));
      });
    });

    test('skip bypasses the limiter', () async {
      await withServer((app) {
        app.use(rateLimit(max: 1, skip: (c) => c.req.path == '/health'));
        app.get('/health', [], (c) => c.text('ok'));
      }, (port) async {
        for (var i = 0; i < 5; i++) {
          final res = await request(port, '/health');
          await bodyOf(res);
          expect(res.statusCode, equals(200));
        }
      });
    });
  });
}
