import 'package:darto/darto.dart';
import 'package:darto/validator.dart';
import 'package:zard/zard.dart';

import 'route.dart';
import 'schema.dart';

/// A [Darto] app with `@hono/zod-openapi`-style OpenAPI support.
///
/// Register routes with [openapi] (validation comes from the zard schemas in
/// the route's [Req]), serve the spec with [doc], and the Scalar UI with
/// [scalarUI].
class OpenAPIDarto extends Darto {
  OpenAPIDarto({super.strict = false});

  final List<RouteConfig> _routes = [];

  /// Mounts [route] on the app and records it for the generated spec.
  ///
  /// Every part declared in `route.request` is validated by its zard schema
  /// (via Darto's `validator` middleware): on failure the request short-circuits
  /// with `400 {error, target, issues}`; on success the parsed value is stored
  /// for `c.req.valid<T>(target)` (`'json'`, `'param'`, `'query'`, `'header'`).
  /// [middlewares] run after validation, before [handler].
  void openapi(
    RouteConfig route,
    List<Middleware> middlewares,
    Handler handler,
  ) {
    final mws = <Middleware>[];
    final req = route.request;
    if (req != null) {
      if (req.json != null) mws.add(_zValidator('json', req.json!.schema));
      if (req.params != null) mws.add(_zValidator('param', req.params!.schema));
      if (req.query != null) mws.add(_zValidator('query', req.query!.schema));
      if (req.headers != null) {
        mws.add(_zValidator('header', req.headers!.schema));
      }
    }
    mws.addAll(middlewares);

    switch (route.method.toLowerCase()) {
      case 'get':
        get(route.path, mws, handler);
        break;
      case 'post':
        post(route.path, mws, handler);
        break;
      case 'put':
        put(route.path, mws, handler);
        break;
      case 'patch':
        patch(route.path, mws, handler);
        break;
      case 'delete':
        delete(route.path, mws, handler);
        break;
      default:
        throw ArgumentError('Unsupported method: ${route.method}');
    }

    _routes.add(route);
  }

  /// Serves the OpenAPI 3.1 document (JSON) at [path].
  void doc(String path, {required Info info, List<Server> servers = const []}) {
    use((Context c, Next next) async {
      if (c.req.path == path) {
        c.json(buildSpec(info, servers));
        return;
      }
      await next();
    });
  }

  /// Assembles the OpenAPI 3.1 document from the registered routes. Named
  /// schemas (`.openapiSchema('Name')`) are emitted once under
  /// `components.schemas` and referenced with `$ref`.
  Map<String, dynamic> buildSpec(Info info, List<Server> servers) {
    final components = <String, dynamic>{};

    Map<String, dynamic> refOrInline(ApiSchema s) {
      if (s.name != null) {
        components[s.name!] = s.toOpenApi();
        return {r'$ref': '#/components/schemas/${s.name}'};
      }
      return s.toOpenApi();
    }

    final paths = <String, Map<String, dynamic>>{};
    for (final route in _routes) {
      final op = <String, dynamic>{};
      if (route.summary != null) op['summary'] = route.summary;
      if (route.description != null) op['description'] = route.description;
      if (route.tags != null && route.tags!.isNotEmpty) op['tags'] = route.tags;

      final parameters = <Map<String, dynamic>>[];
      void addParams(ApiSchema? s, String location, {required bool allRequired}) {
        if (s == null) return;
        final node = s.toOpenApi();
        final props =
            (node['properties'] as Map?)?.cast<String, dynamic>() ?? const {};
        final required =
            (node['required'] as List?)?.cast<String>() ?? const <String>[];
        props.forEach((name, sub) {
          parameters.add({
            'name': name,
            'in': location,
            'required': allRequired || required.contains(name),
            'schema': sub,
          });
        });
      }

      addParams(route.request?.params, 'path', allRequired: true);
      addParams(route.request?.query, 'query', allRequired: false);
      addParams(route.request?.headers, 'header', allRequired: false);
      if (parameters.isNotEmpty) op['parameters'] = parameters;

      final body = route.request?.json;
      if (body != null) {
        op['requestBody'] = {
          'required': true,
          'content': {
            'application/json': {'schema': refOrInline(body)}
          },
        };
      }

      final resp = <String, dynamic>{};
      final responses =
          route.responses.isEmpty ? const [Res(200, 'OK')] : route.responses;
      for (final r in responses) {
        resp['${r.status}'] = {
          'description': r.description,
          if (r.body != null)
            'content': {
              r.contentType: {'schema': refOrInline(r.body!)}
            },
        };
      }
      op['responses'] = resp;

      if (route.security != null && route.security!.isNotEmpty) {
        op['security'] = [
          for (final n in route.security!) {n: <String>[]}
        ];
      }

      final p = _toOpenApiPath(route.path);
      (paths[p] ??= <String, dynamic>{})[route.method.toLowerCase()] = op;
    }

    return {
      'openapi': '3.1.0',
      'info': info.toJson(),
      if (servers.isNotEmpty) 'servers': [for (final s in servers) s.toJson()],
      'paths': paths,
      if (components.isNotEmpty) 'components': {'schemas': components},
    };
  }
}

/// Validates [target] with [schema] via Darto's generic `validator` middleware,
/// short-circuiting with `400` + zard issues on failure.
Middleware _zValidator(String target, Schema schema) {
  return validator(target, (value, c) {
    final result = schema.safeParse(value);
    if (!result.success) {
      return c.json({
        'error': 'Validation failed',
        'target': target,
        'issues':
            result.error?.issues.map((i) => i.message).toList() ?? const [],
      }, 400);
    }
    return result.data;
  });
}

/// A handler that serves the Scalar API reference UI, reading the spec at [url].
/// Mount it like any route: `app.get('/docs', [], scalarUI(url: '/openapi.json'))`.
Handler scalarUI({required String url, String title = 'API Reference'}) {
  return (Context c) => c.html(_scalarHtml(url, title));
}

/// Converts a Darto path (`/users/:id`) to an OpenAPI path (`/users/{id}`),
/// stripping inline regex constraints (`:id(\d+)`).
String _toOpenApiPath(String path) {
  final noRegex = path.replaceAll(RegExp(r'\([^)]*\)'), '');
  return noRegex.replaceAllMapped(RegExp(r':(\w+)\??'), (m) => '{${m[1]}}');
}

String _scalarHtml(String specUrl, String title) => '''
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>$title</title>
  </head>
  <body>
    <script id="api-reference" data-url="$specUrl"></script>
    <script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"></script>
  </body>
</html>
''';
