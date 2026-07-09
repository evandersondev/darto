import 'dart:io';

import 'package:darto/darto.dart';
import 'package:darto_static/darto_static.dart';
import 'package:darto_test/darto_test.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('darto_static_opts_test');
    Directory('${root.path}/assets').createSync();
    // 26 bytes: the alphabet — convenient for range math.
    File('${root.path}/assets/data.txt')
        .writeAsStringSync('abcdefghijklmnopqrstuvwxyz');
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Future<TestClient> boot(Middleware mw, {void Function(Darto)? extra}) async {
    final app = Darto();
    app.use(mw);
    extra?.call(app);
    return TestClient.create(app);
  }

  test('honors a custom urlPrefix', () async {
    final client = await boot(
      serveStatic('assets', rootDir: root.path, urlPrefix: '/static'),
      extra: (app) =>
          app.get('/assets/data.txt', [], (c) => c.text('handler')),
    );
    addTearDown(client.close);

    // Served under the custom prefix...
    final served = await client.get('/static/data.txt');
    expect(served.statusCode, 200);
    expect(served.body, 'abcdefghijklmnopqrstuvwxyz');

    // ...and the default folder path is NOT intercepted (falls through).
    final passthrough = await client.get('/assets/data.txt');
    expect(passthrough.body, 'handler');
  });

  test('sets Cache-Control from maxAge', () async {
    final client = await boot(serveStatic(
      'assets',
      rootDir: root.path,
      maxAge: const Duration(minutes: 5),
    ));
    addTearDown(client.close);

    final res = await client.get('/assets/data.txt');
    expect(res.statusCode, 200);
    expect(res.header('cache-control'), 'public, max-age=300');
  });

  test('serves a byte range as 206 Partial Content', () async {
    final client = await boot(serveStatic('assets', rootDir: root.path));
    addTearDown(client.close);

    final res = await client.get(
      '/assets/data.txt',
      headers: {'Range': 'bytes=5-9'},
    );

    expect(res.statusCode, 206);
    expect(res.body, 'fghij'); // indices 5..9 inclusive
    expect(res.header('content-range'), 'bytes 5-9/26');
    expect(res.header('accept-ranges'), 'bytes');
  });

  test('open-ended range serves to end of file', () async {
    final client = await boot(serveStatic('assets', rootDir: root.path));
    addTearDown(client.close);

    final res = await client.get(
      '/assets/data.txt',
      headers: {'Range': 'bytes=23-'},
    );

    expect(res.statusCode, 206);
    expect(res.body, 'xyz');
    expect(res.header('content-range'), 'bytes 23-25/26');
  });

  test('HEAD returns headers without a body', () async {
    final client = await boot(serveStatic('assets', rootDir: root.path));
    addTearDown(client.close);

    final res = await client.request('HEAD', '/assets/data.txt');
    // 204 No Content: metadata present, body empty.
    expect(res.body, isEmpty);
    expect(res.statusCode, anyOf(200, 204));
  });

  test('non-GET/HEAD methods fall through to the next handler', () async {
    final client = await boot(
      serveStatic('assets', rootDir: root.path),
      extra: (app) =>
          app.post('/assets/data.txt', [], (c) => c.ok({'via': 'handler'})),
    );
    addTearDown(client.close);

    final res = await client.post('/assets/data.txt');
    expect(res.statusCode, 200);
    expect(res.json['via'], 'handler');
  });
}
