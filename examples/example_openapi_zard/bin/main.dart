import 'package:darto_zard_openapi/darto_zard_openapi.dart';

// 2. Schema defined once with zard. .describe()/.example() add OpenAPI metadata;
//    .openapi('User') names the component (#/components/schemas/User).
final userSchema = z.map({
  'name': z.string().min(2).max(50).describe('Nome completo').example('João Silva'),
  'email': z.string().email().describe('E-mail do usuário').example('joao@example.com'),
  'age': z.int().min(0).max(150).describe('Idade em anos').example(28),
  'role': z.$enum(['admin', 'user', 'guest']).describe('Papel do usuário'),
}).openapi('User');

// Params come as strings → z.coerce makes "42" become 42.
final getUserParams = z.map({
  'id': z.coerce.int().min(1).describe('ID do usuário a ser buscado'),
}).openapi();

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
