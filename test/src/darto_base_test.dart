import 'package:darto/darto.dart';
import 'package:test/test.dart';

void main() {
  late Darto app;

  setUp(() {
    app = Darto(logger: true);
  });

  group('Darto', () {
    test('Should set stores a global configuration value', () {
      app.set('key', 'value');
      expect(Darto.settings['key'], equals('value'));
    });

    test('Should get retrieves a global configuration value', () {
      app.set('key', 'value');
      expect(app.get('key'), equals('value'));
    });

    test('Should be throws exception when handler is invalid', () {
      final invalidHandler = 'Invalid Handler';

      expect(() => app.get('/test', invalidHandler),
          throwsA(isA<ArgumentError>()));
      expect(() => app.post('/test', invalidHandler),
          throwsA(isA<ArgumentError>()));
      expect(() => app.put('/test', invalidHandler),
          throwsA(isA<ArgumentError>()));
      expect(() => app.delete('/test', invalidHandler),
          throwsA(isA<ArgumentError>()));
      expect(() => app.patch('/test', invalidHandler),
          throwsA(isA<ArgumentError>()));
      expect(() => app.head('/test', invalidHandler),
          throwsA(isA<ArgumentError>()));
      expect(() => app.trace('/test', invalidHandler),
          throwsA(isA<ArgumentError>()));
      expect(() => app.options('/test', invalidHandler),
          throwsA(isA<ArgumentError>()));
    });

    test('Should be throws exception when register middleware is invalid', () {
      expect(() => app.use(123), throwsA(isA<ArgumentError>()));
    });

    test('Should be adds middleware or static folder', () {
      app.use((req, res, next) => next());
      expect(app.get('/test'), isNull);
    });

    test('Should be adds a static folder', () {
      app.static('public');
      expect(app.get('/test'), isNull);
    });

    test('Should be sets a global timeout', () {
      app.timeout(5000);
      expect(Darto.settings['timeout'], equals(5000));
    });
  });
}
