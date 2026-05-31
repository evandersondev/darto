import 'package:darto/health.dart';
import 'package:test/test.dart';

import '../support/harness.dart';

void main() {
  group('health', () {
    test('returns 200 ok with no checks', () async {
      await withServer((app) {
        app.get('/healthz', [], health());
      }, (port) async {
        final res = await request(port, '/healthz');
        expect(res.statusCode, equals(200));
      });
    });

    test('200 with checks up; includes info', () async {
      await withServer((app) {
        app.get('/readyz', [],
            health(checks: {'db': () => true}, info: () => {'version': '1.2.0'}));
      }, (port) async {
        final res = await request(port, '/readyz');
        expect(res.statusCode, equals(200));
      });
    });

    test('503 when a check fails or throws', () async {
      await withServer((app) {
        app.get('/readyz', [], health(checks: {
          'db': () => true,
          'cache': () => false,
          'queue': () => throw StateError('down'),
        }));
      }, (port) async {
        final res = await request(port, '/readyz');
        expect(res.statusCode, equals(503));
      });
    });
  });
}
