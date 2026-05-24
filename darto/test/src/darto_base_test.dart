import 'package:darto/darto.dart';
import 'package:test/test.dart';

void main() {
  group('Darto', () {
    test('routes getter returns registered routes', () {
      final app = Darto();
      app.get('/users', [], (c) => c.ok([]));
      app.post('/users', [], (c) => c.created({}));
      expect(app.routes.length, equals(2));
      expect(app.routes.map((r) => r.method), containsAll(['GET', 'POST']));
    });

    test('route() registers routes under prefix', () {
      final app = Darto();
      app.route('/api', (r) {
        r.get('/ping', [], (c) => c.ok('pong'));
      });
      expect(app.routes.length, equals(1));
      expect(app.routes.first.path, equals('/api/ping'));
    });
  });
}
