import 'package:darto/darto.dart';
import 'package:darto_test/darto_test.dart';
import 'package:test/test.dart';

Darto buildApp() {
  final app = Darto();
  app.get('/hello', [], (c) => c.ok({'msg': 'hi'}));
  app.post('/echo', [], (c) async => c.created(await c.req.json()));
  app.get('/teapot', [], (c) => c.status(418).text("I'm a teapot"));
  return app;
}

void main() {
  group('TestClient', () {
    late TestClient client;

    setUp(() async => client = await TestClient.create(buildApp()));
    tearDown(() => client.close());

    test('GET returns status and parsed JSON', () async {
      final res = await client.get('/hello');
      expect(res.statusCode, equals(200));
      expect(res.isOk, isTrue);
      expect(res.json['msg'], equals('hi'));
      expect(res.header('content-type'), contains('application/json'));
    });

    test('POST with json body round-trips', () async {
      final res = await client.post('/echo', json: {'name': 'Ada'});
      expect(res.statusCode, equals(201));
      expect(res.json['name'], equals('Ada'));
    });

    test('custom status and text body', () async {
      final res = await client.get('/teapot');
      expect(res.statusCode, equals(418));
      expect(res.body, equals("I'm a teapot"));
      expect(res.isOk, isFalse);
    });

    test('exposes the bound ephemeral port', () {
      expect(client.port, greaterThan(0));
    });
  });
}
