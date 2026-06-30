/// Templates for `darto create <name>`.
library;

String pubspecTemplate(String name) => '''
name: $name
description: A Darto web application
version: 0.0.1
publish_to: none

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  darto: ^1.2.0

dev_dependencies:
  lints: ^5.0.0
  test: ^1.24.0
''';

String serverTemplate(String name) => '''
import 'package:$name/app.dart';

void main() async {
  final app = createApp();
  await app.listen(3000, () => print('Server running on http://localhost:3000'));
}
''';

/// Full app.dart — includes a starter user module.
String appTemplate(String name) => '''
import 'package:darto/cors.dart';
import 'package:darto/darto.dart';

import 'modules/user/user_controller.dart';

Darto createApp() {
  final app = Darto();

  app.use(cors());

  app.route('/users', userRouter);

  app.onError((err, c) => c.internalError({'error': err.message}));
  app.notFound((Context c) => c.notFound({'error': 'Route not found'}));

  return app;
}
''';

/// Minimal app.dart — no modules, just a health-check route.
String blankAppTemplate() => '''
import 'package:darto/darto.dart';

Darto createApp() {
  final app = Darto();

  app.get('/health', [], (Context c) => c.ok({'status': 'ok'}));

  app.onError((err, c) => c.internalError({'error': err.message}));
  app.notFound((Context c) => c.notFound({'error': 'Route not found'}));

  return app;
}
''';

String analysisOptionsTemplate() => '''
include: package:lints/recommended.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
''';

// ─── `--template openapi` ─────────────────────────────────────────────────────
// A project where a single zard schema validates the request AND generates the
// OpenAPI 3.1 document (served with the Scalar UI at /docs).

String openapiPubspecTemplate(String name) => '''
name: $name
description: A Darto API with request validation + OpenAPI 3.1 docs
version: 0.0.1
publish_to: none

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  darto: ^1.2.0
  darto_zard_openapi: ^1.0.0

dev_dependencies:
  darto_test: ^1.1.0
  lints: ^5.0.0
  test: ^1.24.0
''';

/// `lib/schemas/user_schema.dart` — one schema, used to validate AND document.
String openapiUserSchemaTemplate() => '''
import 'package:darto_zard_openapi/darto_zard_openapi.dart';

/// A single source of truth: this schema validates the request body and is
/// emitted as the `User` component in the OpenAPI document.
final userSchema = z.map({
  'name': z.string().min(2).openapi(example: 'Ada', description: 'Full name'),
  'age': z.int().min(0).max(150).openapi(example: 28, description: 'Age in years'),
}).openapiSchema('User');
''';

/// `lib/app.dart` for the openapi template — wires OpenAPIDarto on top of Darto.
String openapiAppTemplate(String name) => '''
import 'package:darto/darto.dart';
import 'package:darto_zard_openapi/darto_zard_openapi.dart';

import 'schemas/user_schema.dart';

Darto createApp() {
  final app = Darto();
  final api = OpenAPIDarto(app); // plug OpenAPI on top of your Darto app

  // GET /users
  api.openapi(
    createRoute(
      method: 'get',
      path: '/users',
      summary: 'List users',
      tags: ['Users'],
      responses: [Res(200, 'OK')],
    ),
    [],
    (Context c) => c.ok([
      {'id': 1, 'name': 'Ada', 'age': 28},
    ]),
  );

  // POST /users — body validated by `userSchema` (and documented from it)
  api.openapi(
    createRoute(
      method: 'post',
      path: '/users',
      summary: 'Create a user',
      tags: ['Users'],
      request: Req(json: userSchema),
      responses: [Res(201, 'Created', body: userSchema)],
    ),
    [],
    (Context c) => c.created(c.req.valid('json')),
  );

  // GET /users/:id — path param coerced + validated
  api.openapi(
    createRoute(
      method: 'get',
      path: '/users/:id',
      summary: 'Get a user by id',
      tags: ['Users'],
      request: Req(params: z.map({'id': z.coerce.int().min(1)}).openapiSchema()),
      responses: [Res(200, 'OK', body: userSchema), Res(404, 'Not found')],
    ),
    [],
    (Context c) {
      final id = c.req.valid('param')['id'];
      return c.ok({'id': id, 'name': 'Ada', 'age': 28});
    },
  );

  // Serve the spec + Scalar UI.
  api.doc('/openapi.json', info: Info(title: '$name API', version: '1.0.0'));
  app.get('/docs', [], scalarUI(url: '/openapi.json'));

  app.onError((err, c) => c.internalError({'error': err.message}));
  app.notFound((Context c) => c.notFound({'error': 'Route not found'}));

  return app;
}
''';

/// `test/app_test.dart` — boots the app and asserts validation + spec.
String openapiTestTemplate(String name) => '''
import 'package:$name/app.dart';
import 'package:darto_test/darto_test.dart';
import 'package:test/test.dart';

void main() {
  late TestClient client;

  setUp(() async => client = await TestClient.create(createApp()));
  tearDown(() => client.close());

  test('GET /users returns a list', () async {
    final res = await client.get('/users');
    expect(res.statusCode, 200);
    expect(res.json, isA<List<dynamic>>());
  });

  test('POST /users validates the body (400 on invalid)', () async {
    final res = await client.post('/users', json: {'name': 'A', 'age': -1});
    expect(res.statusCode, 400);
  });

  test('POST /users accepts a valid body', () async {
    final res = await client.post('/users', json: {'name': 'Ada', 'age': 28});
    expect(res.statusCode, 201);
    expect(res.json['name'], 'Ada');
  });

  test('GET /openapi.json exposes the User component', () async {
    final res = await client.get('/openapi.json');
    expect(res.statusCode, 200);
    expect(res.json['openapi'], startsWith('3.1'));
    expect(res.json['components']['schemas'], contains('User'));
  });
}
''';

String gitignoreTemplate() => '''
.dart_tool/
.packages
build/
pubspec.lock
.env
''';
