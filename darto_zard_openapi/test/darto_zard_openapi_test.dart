import 'package:darto_zard_openapi/darto_zard_openapi.dart';
import 'package:test/test.dart';

void main() {
  group('buildSpec', () {
    // `.openapi(example:, description:)` is type-safe: `example` must match the
    // field's type — `z.int().openapi(example: 'x')` would NOT compile.
    final userSchema = z.map({
      'name': z.string().min(2).openapi(example: 'Ada', description: 'Nome'),
      'email': z.string().email(),
      'role': z.$enum(['admin', 'user']),
    }).openapiSchema('User');

    OpenAPIDarto buildApp() {
      final app = OpenAPIDarto();
      app.openapi(
        createRoute(
          method: 'get',
          path: '/users/:id',
          summary: 'Get a user',
          request: Req(params: z.map({'id': z.coerce.int().min(1)}).openapiSchema()),
          responses: [
            Res(200, 'Found', body: userSchema),
            Res(404, 'Missing'),
          ],
        ),
        [],
        (c) => c.ok({}),
      );
      app.openapi(
        createRoute(
          method: 'post',
          path: '/users',
          request: Req(json: userSchema),
          responses: [Res(201, 'Created', body: userSchema)],
        ),
        [],
        (c) => c.created({}),
      );
      return app;
    }

    test('paths, methods and :id → {id}', () {
      final spec = buildApp().buildSpec(
        const Info(title: 'API', version: '1.0.0'),
        const [],
      );
      expect(spec['openapi'], equals('3.1.0'));
      final paths = spec['paths'] as Map;
      expect(paths.keys, containsAll(['/users/{id}', '/users']));
      expect((paths['/users/{id}'] as Map).keys, contains('get'));
      expect((paths['/users'] as Map).keys, contains('post'));
    });

    test('named schema becomes a component and is referenced via \$ref', () {
      final spec = buildApp().buildSpec(
        const Info(title: 'API', version: '1.0.0'),
        const [],
      );
      final comps = (spec['components'] as Map)['schemas'] as Map;
      expect(comps.keys, contains('User'));

      final user = comps['User'] as Map;
      final props = user['properties'] as Map;
      expect(props['name'], containsPair('minLength', 2));
      expect(props['name'], containsPair('description', 'Nome'));
      expect(props['name'], containsPair('example', 'Ada'));
      expect(props['email'], containsPair('format', 'email'));
      expect(props['role'], containsPair('enum', ['admin', 'user']));

      final post = (spec['paths'] as Map)['/users']['post'] as Map;
      final bodySchema = post['requestBody']['content']['application/json']['schema'];
      expect(bodySchema, equals({r'$ref': '#/components/schemas/User'}));
    });

    test('path params are expanded with coerced type + constraint', () {
      final spec = buildApp().buildSpec(
        const Info(title: 'API', version: '1.0.0'),
        const [],
      );
      final get = (spec['paths'] as Map)['/users/{id}']['get'] as Map;
      final params = (get['parameters'] as List).cast<Map>();
      final id = params.firstWhere((p) => p['name'] == 'id');
      expect(id['in'], equals('path'));
      expect(id['required'], isTrue);
      expect(id['schema'], containsPair('type', 'integer'));
      expect(id['schema'], containsPair('minimum', 1));
    });
  });
}
