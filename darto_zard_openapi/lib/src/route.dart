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

  Map<String, dynamic> toJson() =>
      {'url': url, if (description != null) 'description': description};
}

/// The request contract. Each part is a zard schema bridged with `.openapiSchema()`:
///
/// - [json] — the request body (`requestBody`), validated as a whole.
/// - [params] / [query] / [headers] — **object** schemas whose properties each
///   become an OpenAPI parameter (`in: path | query | header`). Path/query/
///   header values arrive as strings, so use `z.coerce.*` for non-string types.
class Req {
  final ApiSchema? json;
  final ApiSchema? params;
  final ApiSchema? query;
  final ApiSchema? headers;
  const Req({this.json, this.params, this.query, this.headers});
}

/// A documented response, keyed by HTTP [status].
class Res {
  final int status;
  final String description;
  final ApiSchema? body;
  final String contentType;
  const Res(this.status, this.description,
      {this.body, this.contentType = 'application/json'});
}

/// A route contract — the OpenAPI "operation", decoupled from its handler.
/// Build it with [createRoute] and register it with `OpenAPIDarto.openapi`.
class RouteConfig {
  final String method; // get | post | put | patch | delete
  final String path; // darto path, e.g. /users/:id
  final String? summary;
  final String? description;
  final List<String>? tags;
  final List<String>? security;
  final Req? request;
  final List<Res> responses;

  const RouteConfig({
    required this.method,
    required this.path,
    this.summary,
    this.description,
    this.tags,
    this.security,
    this.request,
    this.responses = const [],
  });
}

/// Builds a [RouteConfig] — the Darto analog of `@hono/zod-openapi`'s
/// `createRoute`. The returned value is reusable and independent of any handler.
RouteConfig createRoute({
  required String method,
  required String path,
  String? summary,
  String? description,
  List<String>? tags,
  List<String>? security,
  Req? request,
  List<Res> responses = const [],
}) =>
    RouteConfig(
      method: method,
      path: path,
      summary: summary,
      description: description,
      tags: tags,
      security: security,
      request: request,
      responses: responses,
    );
