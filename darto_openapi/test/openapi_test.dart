import 'package:darto/darto.dart';
import 'package:darto_openapi/darto_openapi.dart';
import 'package:darto_test/darto_test.dart';
import 'package:test/test.dart';

OpenApi buildApi() {
  final app = Darto();
  final api = OpenApi(
    app,
    info: Info(title: 'Blog API', version: '1.0.0'),
    servers: [Server('http://localhost:3000')],
  );

  api.get(
    '/posts/:id',
    summary: 'Get a post',
    tags: ['posts'],
    request: Req(params: {'id': Schema.integer()}),
    responses: {
      200: Res('A post', body: Schema.object({'id': Schema.integer()})),
    },
    handler: (c) => c.ok({'id': c.req.paramInt('id')}),
  );

  api.post(
    '/posts',
    summary: 'Create a post',
    tags: ['posts'],
    request: Req(
      json: Schema.object({
        'title': Schema.string(minLength: 1),
        'tags': Schema.array(Schema.string()),
      }, required: ['title']),
    ),
    responses: {201: Res('Created')},
    handler: (c) => c.created(c.req.valid<Map<String, dynamic>>('json')),
  );

  app.use(api.docs());
  return api;
}

void main() {
  group('darto_openapi', () {
    late TestClient client;

    setUp(() async => client = await TestClient.create(buildApi().app));
    tearDown(() => client.close());

    test('serves the OpenAPI 3.1 spec at /openapi.json', () async {
      final res = await client.get('/openapi.json');
      expect(res.statusCode, equals(200));
      final spec = res.json as Map<String, dynamic>;

      expect(spec['openapi'], equals('3.1.0'));
      expect(spec['info']['title'], equals('Blog API'));

      final paths = spec['paths'] as Map<String, dynamic>;
      expect(paths.keys, containsAll(['/posts/{id}', '/posts']));

      final getPost = paths['/posts/{id}']['get'];
      expect(getPost['summary'], equals('Get a post'));
      expect(getPost['tags'], equals(['posts']));
      final params = getPost['parameters'] as List;
      expect(params.first['name'], equals('id'));
      expect(params.first['in'], equals('path'));

      final createBody = paths['/posts']['post']['requestBody']['content']
          ['application/json']['schema'];
      expect(createBody['required'], contains('title'));
    });

    test('validates the request body and rejects invalid input', () async {
      final bad = await client.post('/posts', json: {'tags': []}); // missing title
      expect(bad.statusCode, equals(400));
      expect((bad.json['issues'] as Map)['json'], isNotEmpty);

      final ok = await client.post('/posts', json: {'title': 'Hello'});
      expect(ok.statusCode, equals(201));
      expect(ok.json['title'], equals('Hello'));
    });

    test('serves the Scalar UI at /docs', () async {
      final res = await client.get('/docs');
      expect(res.statusCode, equals(200));
      expect(res.header('content-type'), contains('text/html'));
      expect(res.body, contains('@scalar/api-reference'));
      expect(res.body, contains('/openapi.json'));
    });
  });
}
