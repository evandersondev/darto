import 'package:darto/darto.dart';
import 'package:darto_openapi/darto_openapi.dart';
import 'package:darto_test/darto_test.dart';
import 'package:test/test.dart';

OpenApi buildApi() {
  final app = Darto();
  final api = OpenApi(
    app,
    info: Info(title: 'API', version: '1.0.0'),
    securitySchemes: {'bearerAuth': SecurityScheme.bearer()},
  );

  api.get(
    '/items/:id',
    request: Req(params: {'id': Schema.integer(minimum: 1)}),
    handler: (c) =>
        c.ok({'id': c.req.valid<Map<String, dynamic>>('param')['id']}),
  );

  api.get(
    '/search',
    request: Req(query: {'page': Schema.integer(minimum: 1)}),
    security: ['bearerAuth'],
    handler: (c) {
      final q = c.req.get('__v_query') as Map?;
      return c.ok({'page': q?['page']});
    },
  );

  app.use(api.docs());
  return api;
}

void main() {
  group('param/query validation (with coercion)', () {
    late TestClient client;
    setUp(() async => client = await TestClient.create(buildApi().app));
    tearDown(() => client.close());

    test('path param coerced to int and returned', () async {
      final res = await client.get('/items/5');
      expect(res.statusCode, equals(200));
      expect(res.json['id'], equals(5)); // coerced from "5"
    });

    test('non-integer path param → 400', () async {
      final res = await client.get('/items/abc');
      expect(res.statusCode, equals(400));
      expect((res.json['issues'] as Map)['param'], isNotEmpty);
    });

    test('path param below minimum → 400', () async {
      final res = await client.get('/items/0');
      expect(res.statusCode, equals(400));
    });

    test('valid query coerced; invalid rejected; absent allowed', () async {
      final ok = await client.get('/search?page=2');
      expect(ok.statusCode, equals(200));
      expect(ok.json['page'], equals(2));

      final bad = await client.get('/search?page=0');
      expect(bad.statusCode, equals(400));

      final absent = await client.get('/search');
      expect(absent.statusCode, equals(200));
      expect(absent.json['page'], isNull);
    });
  });

  group('security schemes', () {
    late TestClient client;
    setUp(() async => client = await TestClient.create(buildApi().app));
    tearDown(() => client.close());

    test('spec exposes components.securitySchemes and per-route security',
        () async {
      final spec = (await client.get('/openapi.json')).json as Map;
      final schemes = spec['components']['securitySchemes'] as Map;
      expect(schemes['bearerAuth']['type'], equals('http'));
      expect(schemes['bearerAuth']['scheme'], equals('bearer'));
      expect(schemes['bearerAuth']['bearerFormat'], equals('JWT'));

      final searchGet = spec['paths']['/search']['get'];
      expect(searchGet['security'], equals([
        {'bearerAuth': <String>[]}
      ]));
    });
  });
}
