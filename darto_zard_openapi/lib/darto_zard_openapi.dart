/// Hono-style `zod-openapi` for Darto.
///
/// Define a [zard](https://pub.dev/packages/zard) schema once and use it as the
/// single source of truth: it **validates** the request (real zard — email,
/// refine, coerce, custom messages) **and** generates the OpenAPI 3.1 document.
///
/// ```dart
/// import 'package:darto/darto.dart';
/// import 'package:darto_zard_openapi/darto_zard_openapi.dart';
///
/// final userSchema = z.map({
///   'name': z.string().min(1).openapi(example: 'Ada', description: 'Full name'),
/// }).openapiSchema('User');
///
/// void main() async {
///   final app = Darto();            // your own Darto app
///   final api = OpenAPIDarto(app);  // plug OpenAPI on top
///
///   final route = createRoute(
///     method: 'post',
///     path: '/users',
///     request: Req(json: userSchema),
///     responses: [Res(201, 'Created', body: userSchema)],
///   );
///
///   api.openapi(route, [], (c) => c.created(c.req.valid('json')));
///
///   api.doc('/openapi.json', info: Info(title: 'Users API', version: '1.0.0'));
///   app.get('/docs', [], scalarUI(url: '/openapi.json'));
///   await app.listen(3000);
/// }
/// ```
library darto_zard_openapi;

// Re-export zard (the schema DSL) for convenience. `darto` is NOT re-exported:
// it's the host framework you plug into — import it explicitly and pass your
// `Darto()` to `OpenAPIDarto(app)`.
export 'package:zard/zard.dart';

export 'src/schema.dart';
export 'src/route.dart';
export 'src/app.dart';
