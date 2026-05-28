/// OpenAPI 3.1 spec generation and Scalar API docs for the
/// [Darto](https://pub.dev/packages/darto) web framework.
///
/// Describe a route once — it is mounted on the app (validating the request
/// body) and recorded for the generated OpenAPI document.
///
/// ```dart
/// import 'package:darto/darto.dart';
/// import 'package:darto_openapi/darto_openapi.dart';
///
/// final app = Darto();
/// final api = OpenApi(app, info: Info(title: 'Blog API', version: '1.0.0'));
///
/// api.post('/posts',
///   summary: 'Create a post',
///   tags: ['posts'],
///   request: Req(json: Schema.object({
///     'title': Schema.string(minLength: 1),
///   }, required: ['title'])),
///   responses: {201: Res('Created')},
///   handler: (c) => c.created(c.req.valid('json')),
/// );
///
/// app.use(api.docs()); // serves /openapi.json and /docs (Scalar)
/// await app.listen(3000);
/// ```
library darto_openapi;

export 'src/client_gen.dart';
export 'src/openapi.dart';
export 'src/schema.dart';
