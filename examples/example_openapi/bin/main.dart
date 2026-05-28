import 'package:darto/darto.dart';
import 'package:darto_openapi/darto_openapi.dart';

void main() async {
  final app = Darto();

  // Describe each route once: the schema validates the request AND feeds the
  // generated OpenAPI document — one source of truth.
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
      200: Res('A post', body: Schema.object({
        'id': Schema.integer(),
        'title': Schema.string(),
      }, required: ['id', 'title'])),
    },
    handler: (c) => c.ok({'id': c.req.paramInt('id'), 'title': 'Hello'}),
  );

  api.post(
    '/posts',
    summary: 'Create a post',
    tags: ['posts'],
    request: Req(json: Schema.object({
      'title': Schema.string(minLength: 1),
      'tags': Schema.array(Schema.string()),
    }, required: ['title'])),
    responses: {201: Res('Created')},
    // The validated body is available via c.req.valid('json'); invalid bodies
    // get an automatic 400 with the issues.
    handler: (c) => c.created(c.req.valid<Map<String, dynamic>>('json')),
  );

  // Mounts GET /openapi.json (the spec) and GET /docs (Scalar UI).
  app.use(api.docs());

  await app.listen(3000, () {
    print('OpenAPI example on http://localhost:3000');
    print('  spec → http://localhost:3000/openapi.json');
    print('  docs → http://localhost:3000/docs');
  });
}
