/// Ergonomic test client for the [Darto] web framework.
///
/// Boots a Darto app on an ephemeral loopback port and drives it with a fluent
/// client — so tests never manage a server or pick a port. The full server
/// pipeline runs (middleware, headers, cookies, streaming), so behavior matches
/// production.
///
/// ```dart
/// import 'package:darto/darto.dart';
/// import 'package:darto_test/darto_test.dart';
/// import 'package:test/test.dart';
///
/// void main() {
///   late TestClient client;
///
///   setUp(() async {
///     final app = Darto();
///     app.get('/hello', [], (c) => c.ok({'msg': 'hi'}));
///     app.post('/echo', [], (c) async => c.created(await c.req.json()));
///     client = await TestClient.create(app);
///   });
///   tearDown(() => client.close());
///
///   test('GET /hello', () async {
///     final res = await client.get('/hello');
///     expect(res.statusCode, 200);
///     expect(res.json['msg'], 'hi');
///   });
///
///   test('POST /echo', () async {
///     final res = await client.post('/echo', json: {'name': 'Ada'});
///     expect(res.statusCode, 201);
///     expect(res.json['name'], 'Ada');
///   });
/// }
/// ```
library darto_test;

export 'src/test_client.dart';
