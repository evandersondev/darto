import 'dart:io';

import 'package:darto/darto.dart';
import 'package:darto_static/darto_static.dart';
import 'package:darto_test/darto_test.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late TestClient client;

  setUp(() async {
    // Lay out: <root>/public/index.html
    root = Directory.systemTemp.createTempSync('darto_static_test');
    Directory('${root.path}/public').createSync();
    File('${root.path}/public/index.html')
        .writeAsStringSync('<h1>hello</h1>');

    final app = Darto();
    app.use(serveStatic('public', rootDir: root.path));
    app.get('/fallthrough', [], (c) => c.ok({'via': 'handler'}));
    client = await TestClient.create(app);
  });

  tearDown(() async {
    await client.close();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('serves an existing file with content-type and ETag', () async {
    final res = await client.get('/public/index.html');

    expect(res.statusCode, 200);
    expect(res.body, contains('<h1>hello</h1>'));
    expect(res.header('content-type'), contains('text/html'));
    expect(res.header('etag'), isNotNull);
  });

  test('returns 304 when If-None-Match matches the ETag', () async {
    final first = await client.get('/public/index.html');
    final etag = first.header('etag')!;

    final second = await client.get(
      '/public/index.html',
      headers: {'If-None-Match': etag},
    );

    expect(second.statusCode, 304);
  });

  test('does not leak files outside the root via "../" traversal', () async {
    // The HTTP layer normalizes `..` before the middleware sees it, so the
    // escaped path no longer matches the prefix — the file is never served.
    // (serveStatic also guards with a 403 for any traversal that survives
    // normalization.)
    final res = await client.get('/public/../../etc/passwd');

    expect(res.statusCode, isNot(200));
    expect(res.body, isNot(contains('root:')));
  });

  test('falls through to the next handler for a missing file', () async {
    // A request under the prefix but with no matching file should not 404 here;
    // it calls next(). With no later route it ends as a 404 from the framework.
    final res = await client.get('/public/missing.html');
    expect(res.statusCode, 404);
  });

  test('ignores requests outside the url prefix (calls next)', () async {
    final res = await client.get('/fallthrough');

    expect(res.statusCode, 200);
    expect(res.json['via'], 'handler');
  });
}
