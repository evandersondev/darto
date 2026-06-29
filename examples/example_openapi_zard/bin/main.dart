import 'package:darto_zard_openapi/darto_zard_openapi.dart';

// 2. Schema defined once with zard. .openapi(example:, description:) adds doc
//    metadata per field — `example` is type-checked against the field's type
//    (String for z.string(), int for z.int()). .openapiSchema('User') names the
//    component (#/components/schemas/User).
final userSchema = z.map({
  'name': z.string().min(2).max(50).openapi(
        example: 'João Silva',
        description: 'Nome completo',
      ),
  'email': z.string().email().openapi(
        example: 'joao@example.com',
        description: 'E-mail do usuário',
      ),
  'age': z.int().min(0).max(150).openapi(
        example: 28,
        description: 'Idade em anos',
      ),
  'role': z.$enum(['admin', 'user', 'guest']).openapi(
        description: 'Papel do usuário',
      ),
}).openapiSchema('User');

// Params come as strings → z.coerce makes "42" become 42.
final getUserParams = z.map({
  'id': z.coerce.int().min(1).openapi(description: 'ID do usuário a ser buscado'),
}).openapiSchema();

void main() async {
  // 1. App OpenAPI (≈ new OpenAPIHono()).
  final app = OpenAPIDarto();

  // 3. Route contract (a reusable value, decoupled from the handler).
  final getUserRoute = createRoute(
    method: 'get',
    path: '/users/:id',
    summary: 'Busca um usuário pelo id',
    tags: ['users'],
    request: Req(params: getUserParams),
    responses: [
      Res(200, 'Usuário encontrado', body: userSchema),
      Res(404, 'Usuário não encontrado'),
    ],
  );

  // 4. Attach the contract + middlewares + handler (≈ app.openapi(route, h)).
  app.openapi(getUserRoute, [], (c) {
    final id = c.req.valid<Map<String, dynamic>>('param')['id']; // int, coercido+validado
    if (id != 123) return c.status(404).json({'message': 'Not Found'});
    return c.ok({'id': 123, 'name': 'João Silva', 'email': 'joao@example.com', 'age': 28, 'role': 'admin'});
  });

  // POST /users — body validated by the SAME zard schema that documents it.
  final createUserRoute = createRoute(
    method: 'post',
    path: '/users',
    summary: 'Cria um usuário',
    tags: ['users'],
    request: Req(json: userSchema),
    responses: [Res(201, 'Criado', body: userSchema)],
  );

  app.openapi(createUserRoute, [], (c) {
    final body = c.req.valid<Map<String, dynamic>>('json'); // validado pelo zard
    return c.created(body);
  });

  // 5. OpenAPI spec JSON (≈ app.doc()).
  app.doc('/openapi.json',
      info: Info(title: 'Users API', version: '1.0.0'),
      servers: [Server('http://localhost:3000')]);

  // 6. Scalar UI (≈ swaggerUI).
  app.get('/docs', [], scalarUI(url: '/openapi.json'));

  await app.listen(3000, () {
    print('Users API on http://localhost:3000');
    print('  spec → http://localhost:3000/openapi.json');
    print('  docs → http://localhost:3000/docs');
  });
}
