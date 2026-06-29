# example_openapi_zard

Hono-style `zod-openapi` DX in Darto, using **`darto_zard_openapi`**: a single
zard schema both **validates** the request and **documents** the API.

```dart
import 'package:darto/darto.dart';
import 'package:darto_zard_openapi/darto_zard_openapi.dart';

final userSchema = z.map({
  'name':  z.string().min(2).openapi(example: 'João Silva', description: 'Nome completo'),
  'email': z.string().email(),
  'role':  z.$enum(['admin', 'user', 'guest']),
}).openapiSchema('User'); // named component → #/components/schemas/User

void main() async {
  final app = Darto();            // your own Darto app
  final api = OpenAPIDarto(app);  // plug OpenAPI on top

  final route = createRoute(
    method: 'get',
    path: '/users/:id',
    request: Req(params: z.map({'id': z.coerce.int().min(1)}).openapiSchema()),
    responses: [Res(200, 'Usuário encontrado', body: userSchema)],
  );

  api.openapi(route, [], (c) {
    final id = c.req.valid<Map<String, dynamic>>('param')['id'];
    if (id != 123) return c.status(404).json({'message': 'Not Found'});
    return c.ok({'id': 123, 'name': 'João Silva'});
  });

  api.doc('/openapi.json', info: Info(title: 'Users API', version: '1.0.0'));
  app.get('/docs', [], scalarUI(url: '/openapi.json'));
  await app.listen(3000);
}
```

## Run

```bash
dart pub get
dart run bin/main.dart
```

- `GET http://localhost:3000/openapi.json` — the OpenAPI 3.1 document (with the
  `User` component, constraints, `example` and `description`).
- `GET http://localhost:3000/docs` — the Scalar API reference UI.

Use `api.http` to fire sample requests (valid + invalid). Invalid requests get a
`400` with zard's messages — including things the previous approach couldn't
catch, like `Invalid email format`.

See `darto_zard_openapi`'s README for the full `@hono/zod-openapi` mapping.
