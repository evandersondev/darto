import 'package:darto_test/darto_test.dart';
import 'package:example_test/app.dart';
import 'package:test/test.dart';

void main() {
  late TestClient client;

  // Each group gets a fresh app — no shared state between groups.
  setUp(() async => client = await TestClient.create(buildApp()));
  tearDown(() => client.close());

  group('GET /users', () {
    test('returns empty list on a fresh app', () async {
      final res = await client.get('/users');
      expect(res.statusCode, 200);
      expect(res.json, isEmpty);
    });

    test('lists users after creation', () async {
      await client.post('/users', json: {'name': 'Alice'});
      await client.post('/users', json: {'name': 'Bob'});

      final res = await client.get('/users');
      expect(res.statusCode, 200);
      expect(res.json, hasLength(2));
    });
  });

  group('POST /users', () {
    test('creates a user and returns 201', () async {
      final res = await client.post('/users', json: {'name': 'Alice'});
      expect(res.statusCode, 201);
      expect(res.json['name'], 'Alice');
      expect(res.json['id'], isNotNull);
    });
  });

  group('GET /users/:id', () {
    test('returns the user when found', () async {
      final created = await client.post('/users', json: {'name': 'Alice'});
      final id = created.json['id'];

      final res = await client.get('/users/$id');
      expect(res.statusCode, 200);
      expect(res.json['name'], 'Alice');
    });

    test('returns 404 for unknown id', () async {
      final res = await client.get('/users/999');
      expect(res.statusCode, 404);
      expect(res.json['error'], 'not found');
    });
  });

  group('PUT /users/:id', () {
    test('updates the user name', () async {
      final created = await client.post('/users', json: {'name': 'Alice'});
      final id = created.json['id'];

      final res = await client.put('/users/$id', json: {'name': 'Alicia'});
      expect(res.statusCode, 200);
      expect(res.json['name'], 'Alicia');
    });

    test('returns 404 when user does not exist', () async {
      final res = await client.put('/users/999', json: {'name': 'Ghost'});
      expect(res.statusCode, 404);
    });
  });

  group('DELETE /users/:id', () {
    test('removes the user and returns 204', () async {
      final created = await client.post('/users', json: {'name': 'Alice'});
      final id = created.json['id'];

      final del = await client.delete('/users/$id');
      expect(del.statusCode, 204);

      final get = await client.get('/users/$id');
      expect(get.statusCode, 404);
    });
  });

  group('middleware', () {
    test('every response carries X-Powered-By header', () async {
      final res = await client.get('/users');
      expect(res.header('x-powered-by'), 'Darto');
    });
  });
}
