import 'package:darto/etag.dart';
import 'package:test/test.dart';

import '../support/harness.dart';

void main() {
  group('etag', () {
    test('sets an ETag and returns 304 on matching If-None-Match', () async {
      await withServer((app) {
        app.use(etag());
        app.get('/data', [], (c) => c.json({'hello': 'world'}));
      }, (port) async {
        final first = await request(port, '/data');
        await bodyOf(first);
        final tag = first.headers.value('etag');
        expect(first.statusCode, equals(200));
        expect(tag, isNotNull);

        final second =
            await request(port, '/data', headers: {'if-none-match': tag!});
        expect(second.statusCode, equals(304));
        expect(second.headers.value('etag'), equals(tag));
        expect(await bodyOf(second), isEmpty);
      });
    });

    test('different bodies produce different ETags', () async {
      await withServer((app) {
        app.use(etag());
        app.get('/a', [], (c) => c.json({'v': 1}));
        app.get('/b', [], (c) => c.json({'v': 2}));
      }, (port) async {
        final a = await request(port, '/a');
        await bodyOf(a);
        final b = await request(port, '/b');
        await bodyOf(b);

        expect(a.headers.value('etag'), isNotNull);
        expect(a.headers.value('etag'), isNot(equals(b.headers.value('etag'))));
      });
    });
  });
}
