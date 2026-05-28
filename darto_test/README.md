# darto_test

Ergonomic test client for the [Darto](https://pub.dev/packages/darto) web
framework. Boot an app and assert responses **without managing a server or
picking a port**.

`TestClient` boots your app on an ephemeral loopback port and drives it with a
fluent HTTP client (supertest-style). The full server pipeline runs — middleware,
headers, cookies, streaming, redirects — so behavior matches production.

## Install

```yaml
dev_dependencies:
  darto_test: ^1.0.0
```

## Usage

```dart
import 'package:darto/darto.dart';
import 'package:darto_test/darto_test.dart';
import 'package:test/test.dart';

Darto buildApp() {
  final app = Darto();
  app.get('/hello', [], (c) => c.ok({'msg': 'hi'}));
  app.post('/echo', [], (c) async => c.created(await c.req.json()));
  return app;
}

void main() {
  late TestClient client;

  setUp(() async => client = await TestClient.create(buildApp()));
  tearDown(() => client.close());

  test('GET /hello', () async {
    final res = await client.get('/hello');
    expect(res.statusCode, 200);
    expect(res.json['msg'], 'hi');
  });

  test('POST /echo', () async {
    final res = await client.post('/echo', json: {'name': 'Ada'});
    expect(res.statusCode, 201);
    expect(res.json['name'], 'Ada');
  });
}
```

## API

### `TestClient`

| Member | Description |
|---|---|
| `static Future<TestClient> create(Darto app)` | Boots `app` on a free loopback port |
| `get / head / options(path, {headers})` | Send a request without a body |
| `post / put / patch / delete(path, {headers, body, json})` | Send a request with an optional body |
| `request(method, path, {headers, body, json})` | Generic request |
| `port` | The bound ephemeral port |
| `close()` | Stops the app and closes the client |

Pass `json:` to send a JSON body (sets `Content-Type: application/json`), or
`body:` for a raw `String` / `List<int>` payload.

### `TestResponse`

| Member | Description |
|---|---|
| `statusCode` | HTTP status code |
| `body` | Raw body as UTF-8 text |
| `json` | Body parsed as JSON (`null` when empty) |
| `header(name)` | Response header (case-insensitive) |
| `headers` | All headers (lowercased keys) |
| `cookie(name)` / `cookies` | `Set-Cookie` lookup / list |
| `isOk` | `true` for 2xx |

<br/>

---

<br/>

### Support 💖

If you find Darto Test useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the package and make it even better!

<br/>
