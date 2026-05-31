import 'package:darto/request_id.dart';
import 'package:test/test.dart';

import '../support/harness.dart';

void main() {
  group('requestId', () {
    test('generates a UUID and echoes it in the response header', () async {
      await withServer((app) {
        app.use(requestId());
        app.get('/', [], (c) => c.text(requestIdOf(c)));
      }, (port) async {
        final res = await request(port, '/');
        final body = await bodyOf(res);
        final header = res.headers.value('x-request-id');

        expect(header, isNotNull);
        expect(header, equals(body));
        expect(body, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
            r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
      });
    });

    test('honors an incoming request id', () async {
      await withServer((app) {
        app.use(requestId());
        app.get('/', [], (c) => c.text(requestIdOf(c)));
      }, (port) async {
        final res =
            await request(port, '/', headers: {'x-request-id': 'abc-123'});
        expect(await bodyOf(res), equals('abc-123'));
        expect(res.headers.value('x-request-id'), equals('abc-123'));
      });
    });
  });
}
