import 'package:darto/darto.dart';

import 'schema.dart';

/// OpenAPI `info` object.
class Info {
  final String title;
  final String version;
  final String? description;
  const Info({required this.title, required this.version, this.description});

  Map<String, dynamic> toJson() => {
        'title': title,
        'version': version,
        if (description != null) 'description': description,
      };
}

/// OpenAPI `server` object.
class Server {
  final String url;
  final String? description;
  const Server(this.url, {this.description});

  Map<String, dynamic> toJson() => {
        'url': url,
        if (description != null) 'description': description,
      };
}

/// The request contract for a route — documents **and** validates.
///
/// [json] validates the request body and is emitted as `requestBody`. [params],
/// [query] and [headers] are documented as OpenAPI parameters.
class Req {
  final Schema? json;
  final Map<String, Schema>? params;
  final Map<String, Schema>? query;
  final Map<String, Schema>? headers;
  const Req({this.json, this.params, this.query, this.headers});
}

/// A documented response.
class Res {
  final String description;
  final Schema? body;
  final String contentType;
  const Res(this.description, {this.body, this.contentType = 'application/json'});
}

/// An OpenAPI security scheme (emitted under `components.securitySchemes`).
///
/// Reference it per route via `security: ['<name>']`.
class SecurityScheme {
  final Map<String, dynamic> node;
  const SecurityScheme._(this.node);

  /// HTTP `Authorization` scheme (e.g. `bearer`, `basic`).
  factory SecurityScheme.http({
    required String scheme,
    String? bearerFormat,
    String? description,
  }) =>
      SecurityScheme._({
        'type': 'http',
        'scheme': scheme,
        if (bearerFormat != null) 'bearerFormat': bearerFormat,
        if (description != null) 'description': description,
      });

  /// Bearer token (`Authorization: Bearer …`), defaulting to JWT.
  factory SecurityScheme.bearer({String bearerFormat = 'JWT', String? description}) =>
      SecurityScheme.http(
          scheme: 'bearer', bearerFormat: bearerFormat, description: description);

  /// HTTP Basic auth.
  factory SecurityScheme.basic({String? description}) =>
      SecurityScheme.http(scheme: 'basic', description: description);

  /// API key in a header, query param or cookie ([location] = `header` |
  /// `query` | `cookie`).
  factory SecurityScheme.apiKey({
    required String name,
    String location = 'header',
    String? description,
  }) =>
      SecurityScheme._({
        'type': 'apiKey',
        'name': name,
        'in': location,
        if (description != null) 'description': description,
      });
}

class _Operation {
  final String method; // lowercase
  final String path; // darto path (e.g. /posts/:id)
  final String? summary;
  final String? description;
  final List<String>? tags;
  final Req? request;
  final Map<int, Res>? responses;
  final List<String>? security;

  _Operation(this.method, this.path, this.summary, this.description, this.tags,
      this.request, this.responses, this.security);

  Map<String, dynamic> toObject() {
    final obj = <String, dynamic>{};
    if (summary != null) obj['summary'] = summary;
    if (description != null) obj['description'] = description;
    if (tags != null && tags!.isNotEmpty) obj['tags'] = tags;

    final parameters = <Map<String, dynamic>>[];
    request?.params?.forEach((name, s) => parameters.add(
        {'name': name, 'in': 'path', 'required': true, 'schema': s.node}));
    request?.query?.forEach((name, s) => parameters.add(
        {'name': name, 'in': 'query', 'required': false, 'schema': s.node}));
    request?.headers?.forEach((name, s) => parameters.add(
        {'name': name, 'in': 'header', 'required': false, 'schema': s.node}));
    if (parameters.isNotEmpty) obj['parameters'] = parameters;

    if (request?.json != null) {
      obj['requestBody'] = {
        'required': true,
        'content': {
          'application/json': {'schema': request!.json!.node}
        },
      };
    }

    final resp = <String, dynamic>{};
    (responses ?? const {200: Res('OK')}).forEach((code, r) {
      resp['$code'] = {
        'description': r.description,
        if (r.body != null)
          'content': {
            r.contentType: {'schema': r.body!.node}
          },
      };
    });
    obj['responses'] = resp;

    if (security != null && security!.isNotEmpty) {
      obj['security'] = [
        for (final name in security!) {name: <String>[]}
      ];
    }
    return obj;
  }
}

/// OpenAPI 3.1 registry for a [Darto] app.
///
/// Use `get`/`post`/… to register a route **once** — it is mounted on the app
/// (with request validation when a `request.json` schema is given) and recorded
/// for the generated spec. Mount [docs] to serve `/openapi.json` and a Scalar
/// API reference UI.
///
/// ```dart
/// final app = Darto();
/// final api = OpenApi(app, info: Info(title: 'Blog API', version: '1.0.0'));
///
/// api.post('/posts',
///   summary: 'Create a post',
///   tags: ['posts'],
///   request: Req(json: Schema.object({'title': Schema.string(minLength: 1)})),
///   responses: {201: Res('Created')},
///   handler: (c) => c.created(c.req.valid('json')),
/// );
///
/// app.use(api.docs()); // /openapi.json + /docs (Scalar)
/// ```
class OpenApi {
  final Darto app;
  final Info info;
  final List<Server> servers;
  final Map<String, SecurityScheme> securitySchemes;

  final List<_Operation> _ops = [];
  Map<String, dynamic>? _cachedSpec;

  OpenApi(
    this.app, {
    required this.info,
    this.servers = const [],
    this.securitySchemes = const {},
  });

  void get(String path,
          {String? summary,
          String? description,
          List<String>? tags,
          Req? request,
          Map<int, Res>? responses,
          List<String>? security,
          List<Middleware> middlewares = const [],
          required Handler handler}) =>
      _add('get', path, summary, description, tags, request, responses,
          security, middlewares, handler);

  void post(String path,
          {String? summary,
          String? description,
          List<String>? tags,
          Req? request,
          Map<int, Res>? responses,
          List<String>? security,
          List<Middleware> middlewares = const [],
          required Handler handler}) =>
      _add('post', path, summary, description, tags, request, responses,
          security, middlewares, handler);

  void put(String path,
          {String? summary,
          String? description,
          List<String>? tags,
          Req? request,
          Map<int, Res>? responses,
          List<String>? security,
          List<Middleware> middlewares = const [],
          required Handler handler}) =>
      _add('put', path, summary, description, tags, request, responses,
          security, middlewares, handler);

  void patch(String path,
          {String? summary,
          String? description,
          List<String>? tags,
          Req? request,
          Map<int, Res>? responses,
          List<String>? security,
          List<Middleware> middlewares = const [],
          required Handler handler}) =>
      _add('patch', path, summary, description, tags, request, responses,
          security, middlewares, handler);

  void delete(String path,
          {String? summary,
          String? description,
          List<String>? tags,
          Req? request,
          Map<int, Res>? responses,
          List<String>? security,
          List<Middleware> middlewares = const [],
          required Handler handler}) =>
      _add('delete', path, summary, description, tags, request, responses,
          security, middlewares, handler);

  void _add(
    String method,
    String path,
    String? summary,
    String? description,
    List<String>? tags,
    Req? request,
    Map<int, Res>? responses,
    List<String>? security,
    List<Middleware> middlewares,
    Handler handler,
  ) {
    final mws = <Middleware>[...middlewares];
    if (request != null) mws.insert(0, _requestValidator(request));

    switch (method) {
      case 'get':
        app.get(path, mws, handler);
        break;
      case 'post':
        app.post(path, mws, handler);
        break;
      case 'put':
        app.put(path, mws, handler);
        break;
      case 'patch':
        app.patch(path, mws, handler);
        break;
      case 'delete':
        app.delete(path, mws, handler);
        break;
    }

    _ops.add(_Operation(method, path, summary, description, tags, request,
        responses, security));
    _cachedSpec = null;
  }

  /// The full OpenAPI 3.1 document.
  Map<String, dynamic> toJson() {
    final paths = <String, Map<String, dynamic>>{};
    for (final op in _ops) {
      final p = _toOpenApiPath(op.path);
      (paths[p] ??= <String, dynamic>{})[op.method] = op.toObject();
    }
    return {
      'openapi': '3.1.0',
      'info': info.toJson(),
      if (servers.isNotEmpty) 'servers': [for (final s in servers) s.toJson()],
      'paths': paths,
      if (securitySchemes.isNotEmpty)
        'components': {
          'securitySchemes': {
            for (final e in securitySchemes.entries) e.key: e.value.node,
          },
        },
    };
  }

  /// Global middleware that serves the spec at [specPath] and a Scalar API
  /// reference UI at [uiPath].
  Middleware docs({
    String specPath = '/openapi.json',
    String uiPath = '/docs',
    String? title,
  }) {
    return (Context c, Next next) async {
      final path = c.req.path;
      if (path == specPath) {
        c.json(_cachedSpec ??= toJson());
        return;
      }
      if (path == uiPath) {
        c.html(_scalarHtml(specPath, title ?? info.title));
        return;
      }
      await next();
    };
  }
}

/// Validates the parts of [req] that declare a schema, storing the validated
/// values under `__v_<target>` for `c.req.valid('<target>')`. Path/query/header
/// values arrive as strings and are coerced to the declared scalar type before
/// validation. Query/header params are optional when absent; path params are
/// always present.
Middleware _requestValidator(Req req) {
  return (Context c, Next next) async {
    final issues = <String, List<String>>{};

    if (req.json != null) {
      final body = await c.req.json<dynamic>();
      final errs = req.json!.validate(body);
      if (errs.isNotEmpty) {
        issues['json'] = errs;
      } else {
        c.set('__v_json', body);
      }
    }

    void validateParams(
      String target,
      Map<String, Schema> schemas,
      String? Function(String name) read, {
      required bool optionalWhenAbsent,
    }) {
      final errs = <String>[];
      final out = <String, dynamic>{};
      schemas.forEach((name, schema) {
        final raw = read(name);
        if (raw == null) {
          if (!optionalWhenAbsent) errs.addAll(schema.validate(null, name));
          return;
        }
        final value = _coerce(schema.node, raw);
        final e = schema.validate(value, name);
        if (e.isEmpty) {
          out[name] = value;
        } else {
          errs.addAll(e);
        }
      });
      if (errs.isNotEmpty) {
        issues[target] = errs;
      } else if (out.isNotEmpty) {
        c.set('__v_$target', out);
      }
    }

    if (req.params != null) {
      validateParams('param', req.params!, c.req.param,
          optionalWhenAbsent: false);
    }
    if (req.query != null) {
      validateParams('query', req.query!, c.req.query,
          optionalWhenAbsent: true);
    }
    if (req.headers != null) {
      validateParams('header', req.headers!, c.req.header,
          optionalWhenAbsent: true);
    }

    if (issues.isNotEmpty) {
      c.status(400).json({'error': 'Validation failed', 'issues': issues});
      return;
    }
    await next();
  };
}

/// Coerces a raw string [raw] to the scalar type declared in OpenAPI [node].
/// Falls back to the original string when it can't be parsed (so validation
/// reports a clear type error).
Object? _coerce(Map<String, dynamic> node, String raw) {
  final type = node['type'];
  final primary = type is List
      ? type.cast<String>().firstWhere((t) => t != 'null', orElse: () => 'string')
      : (type as String? ?? 'string');
  switch (primary) {
    case 'integer':
      return int.tryParse(raw) ?? raw;
    case 'number':
      return num.tryParse(raw) ?? raw;
    case 'boolean':
      if (raw == 'true') return true;
      if (raw == 'false') return false;
      return raw;
    default:
      return raw;
  }
}

/// Converts a Darto path (`/posts/:id`) to an OpenAPI path (`/posts/{id}`),
/// stripping inline regex constraints (`:id(\d+)`).
String _toOpenApiPath(String path) {
  final noRegex = path.replaceAll(RegExp(r'\([^)]*\)'), '');
  return noRegex.replaceAllMapped(
      RegExp(r':(\w+)\??'), (m) => '{${m[1]}}');
}

String _scalarHtml(String specPath, String title) => '''
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>$title</title>
  </head>
  <body>
    <script id="api-reference" data-url="$specPath"></script>
    <script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"></script>
  </body>
</html>
''';
