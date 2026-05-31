import 'dart:convert';

import 'package:darto/darto.dart';
import 'package:darto_inject/darto_inject.dart';
import 'package:darto_test/darto_test.dart';
import 'package:test/test.dart';

void main() {
  group('Di container', () {
    test('app-scope provider is built once per container', () {
      var calls = 0;
      final counter = Provider<int>((di) {
        calls++;
        return 42;
      });
      final di = Di(providers: [counter]);

      expect(di.read(counter), 42);
      expect(di.read(counter), 42);
      expect(calls, 1);
    });

    test('one provider can read another at build time', () {
      final a = Provider<int>((di) => 7);
      final b = Provider<int>((di) => di.read(a) * 6);
      final di = Di(providers: [a, b]);

      expect(di.read(b), 42);
    });

    test('overriding a provider replaces its factory', () {
      final dbUrl = Provider<String>((di) => 'prod://server');
      final di = Di(providers: [dbUrl])
        ..override(dbUrl, (di) => 'memory://test');

      expect(di.read(dbUrl), 'memory://test');
    });

    test('dispose() runs onDispose in reverse creation order', () async {
      final order = <String>[];
      final a = Provider<String>(
        (di) => 'a',
        onDispose: (_) => order.add('a'),
      );
      final b = Provider<String>(
        (di) {
          di.read(a);
          return 'b';
        },
        onDispose: (_) => order.add('b'),
      );
      final di = Di(providers: [a, b]);
      di.read(b);

      await di.dispose();
      // b was created last, must dispose first
      expect(order, equals(['b', 'a']));
    });

    test('reading an app-scope provider after dispose throws', () async {
      final p = Provider<int>((di) => 1);
      final di = Di(providers: [p]);
      di.read(p);
      await di.dispose();
      expect(() => di.read(p), throwsStateError);
    });

    test('reading a request-scope provider on the container throws', () {
      final p = Provider<int>((di) => 1, scope: Scope.request);
      final di = Di(providers: [p]);
      expect(() => di.read(p), throwsStateError);
    });
  });

  group('AsyncProvider', () {
    test('caches the resolved Future result for app scope', () async {
      var calls = 0;
      final p = AsyncProvider<int>((di) async {
        calls++;
        return 100;
      });
      final di = Di(asyncProviders: [p]);

      expect(await di.readAsync(p), 100);
      expect(await di.readAsync(p), 100);
      expect(calls, 1);
    });
  });

  group('c.read on request', () {
    test('app-scope service is shared across requests', () async {
      final counter = Provider<List<int>>((di) => <int>[]);
      final di = Di(providers: [counter]);

      final app = Darto()..use(di.middleware());
      app.post('/inc', [], (c) {
        c.read(counter).add(1);
        return c.ok({'size': c.read(counter).length});
      });

      final client = await TestClient.create(app);
      await client.post('/inc');
      await client.post('/inc');
      final res = await client.post('/inc');
      expect(jsonDecode(res.body), {'size': 3});
      await client.close();
      await di.dispose();
    });

    test('request-scope provider is recreated per request and disposed', () async {
      final created = <int>[];
      final disposed = <int>[];
      var seq = 0;
      final reqIdProvider = Provider<int>(
        (di) {
          final id = ++seq;
          created.add(id);
          return id;
        },
        scope: Scope.request,
        onDispose: (id) => disposed.add(id),
      );
      final di = Di(providers: [reqIdProvider]);

      final app = Darto()..use(di.middleware());
      app.get('/id', [], (c) => c.ok({'id': c.read(reqIdProvider)}));

      final client = await TestClient.create(app);
      final a = await client.get('/id');
      final b = await client.get('/id');
      expect(jsonDecode(a.body)['id'], 1);
      expect(jsonDecode(b.body)['id'], 2);
      expect(created, equals([1, 2]));
      expect(disposed, equals([1, 2]));
      await client.close();
      await di.dispose();
    });

    test('contextProvider exposes the current Context to factories', () async {
      final pathProvider = Provider<String>(
        (di) => di.read(contextProvider).req.url.path,
        scope: Scope.request,
      );
      final di = Di(providers: [pathProvider]);

      final app = Darto()..use(di.middleware());
      app.get('/here', [], (c) => c.text(c.read(pathProvider)));

      final client = await TestClient.create(app);
      final res = await client.get('/here');
      expect(res.body, contains('/here'));
      await client.close();
      await di.dispose();
    });

    test('reading without the di middleware throws a helpful error', () async {
      final p = Provider<int>((di) => 1);
      final app = Darto();
      // No app.use(di.middleware())!
      app.get('/x', [], (c) {
        try {
          c.read(p);
          return c.text('ok');
        } on StateError catch (e) {
          return c.text('boom: ${e.message}', 500);
        }
      });

      final client = await TestClient.create(app);
      final res = await client.get('/x');
      expect(res.statusCode, 500);
      expect(res.body, contains('container.middleware()'));
      await client.close();
    });

    test('override on the container is visible from the request scope', () async {
      final greeting = Provider<String>((di) => 'hello');
      final di = Di(providers: [greeting])
        ..override(greeting, (di) => 'olá');

      final app = Darto()..use(di.middleware());
      app.get('/g', [], (c) => c.text(c.read(greeting)));

      final client = await TestClient.create(app);
      final res = await client.get('/g');
      expect(res.body, 'olá');
      await client.close();
      await di.dispose();
    });
  });

  group('Feature', () {
    test('install(prefix, feature) mounts routes under the prefix', () async {
      final f = Feature(
        routes: (r) {
          r.get('/ping', [], (c) => c.text('pong'));
        },
      );
      final app = Darto()..install('/api', f);

      final client = await TestClient.create(app);
      final res = await client.get('/api/ping');
      expect(res.body, 'pong');
      await client.close();
    });

    test('install(feature) without prefix registers at root', () async {
      final f = Feature(
        routes: (r) {
          r.get('/root', [], (c) => c.text('here'));
        },
      );
      final app = Darto()..install(f);

      final client = await TestClient.create(app);
      final res = await client.get('/root');
      expect(res.body, 'here');
      await client.close();
    });

    test('collectProviders flattens features into Di lists', () {
      final a = Provider<int>((di) => 1);
      final b = AsyncProvider<int>((di) async => 2);
      final f1 = Feature(providers: [a], routes: (_) {});
      final f2 = Feature(asyncProviders: [b], routes: (_) {});

      final (sync, async) = collectProviders([f1, f2]);
      expect(sync, [a]);
      expect(async, [b]);
    });
  });

  group('warmup', () {
    test('eagerly builds every app-scope provider before the first request', () async {
      final order = <String>[];
      final a = Provider<int>((di) {
        order.add('a');
        return 1;
      });
      final b = AsyncProvider<int>((di) async {
        order.add('b');
        return 2;
      });
      final di = Di(providers: [a], asyncProviders: [b]);

      await di.warmup();
      expect(order, containsAll(['a', 'b']));
    });
  });
}
