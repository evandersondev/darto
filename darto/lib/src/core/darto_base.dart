import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:mime/mime.dart';

import 'darto_response.dart';

part 'context.dart';
part 'request.dart';
part 'response.dart';
part 'router.dart';

// ── Typedefs ──────────────────────────────────────────────────────────────────

typedef Next = Future<void> Function();
typedef Handler = FutureOr<Response>? Function(Context c);
typedef Middleware = FutureOr<void> Function(Context c, Next next);
typedef ErrorHandler = FutureOr<Response> Function(DartoError error, Context c);

/// Layout function registered via [Context.setRender].
///
/// Receives the inner HTML [content] produced by the handler and an optional
/// [props] map (e.g. page title, meta tags), and must return a full [Response]
/// — typically `c.html(...)`.
typedef RenderLayout = FutureOr<Response> Function(
  String content,
  Map<String, dynamic> props,
);

// ── DartoError ────────────────────────────────────────────────────────────────

/// Wraps an unhandled exception caught during request processing.
///
/// Passed to the handler registered with [Darto.onError].
///
/// ```dart
/// app.onError((err, c) {
///   print(err.message);
///   print(err.stackTrace);
///   return c.internalError({'error': err.message});
/// });
/// ```
class DartoError {
  /// The original thrown object.
  final Object cause;

  /// The stack trace captured at the throw site.
  final StackTrace stackTrace;

  DartoError(this.cause, this.stackTrace);

  /// Shorthand for `cause.toString()`.
  String get message => cause.toString();

  @override
  String toString() => 'DartoError: $message\n$stackTrace';
}

// ── RouteSpec ─────────────────────────────────────────────────────────────────

/// Metadata for a registered route — used by code generators.
class RouteSpec {
  final String method;
  final String path;
  const RouteSpec({required this.method, required this.path});
  @override
  String toString() => '$method $path';
}

// ── _Route ────────────────────────────────────────────────────────────────────

class _Route {
  final String? path;
  final RegExp? regex;
  final List<String> paramNames;
  final String? method;
  final List<Middleware> middlewares;
  final Handler? handler;
  final String? groupPrefix;

  const _Route({
    this.path,
    this.regex,
    this.paramNames = const [],
    this.method,
    this.middlewares = const [],
    this.handler,
    this.groupPrefix,
  });
}

// ── Darto ─────────────────────────────────────────────────────────────────────

class Darto {
  final bool strict;

  Darto({this.strict = false});

  final List<_Route> _routes = [];
  String? _routePrefix;

  ErrorHandler? _onErrorHandler;
  Handler? _notFoundHandler;
  HttpServer? _server;

  bool get isRunning => _server != null;

  /// Sets a global path prefix applied to every route registered on this
  /// instance.  Returns [this] for fluent configuration.
  ///
  /// ```dart
  /// final app = Darto().basePath('/v1');
  /// app.get('/posts', handler); // registered as /v1/posts
  /// ```
  Darto basePath(String prefix) {
    _routePrefix = _normalizePath(prefix);
    return this;
  }

  /// All named routes — useful for client generators.
  List<RouteSpec> get routes => _routes
      .where((r) => r.method != null && r.path != null)
      .map((r) => RouteSpec(method: r.method!, path: r.path!))
      .toList();

  /// Detailed route info for dev tools — exposes middleware count per route.
  List<({String method, String path, int middlewareCount})> get routeEntries =>
      _routes
          .where((r) => r.method != null && r.path != null)
          .map((r) => (
                method: r.method!,
                path: r.path!,
                middlewareCount: r.middlewares.length,
              ))
          .toList();

  // ── Error handlers ────────────────────────────────────────────────────────

  void onError(ErrorHandler handler) => _onErrorHandler = handler;

  void notFound(Handler handler) => _notFoundHandler = handler;

  // ── Middleware ────────────────────────────────────────────────────────────

  /// Registers [m] as a global middleware — runs for every request.
  ///
  /// ```dart
  /// app.use(logger());
  /// app.use(cors());
  /// ```
  void use(Middleware m) {
    _routes.add(_Route(middlewares: [m]));
  }

  /// Registers [m] as a path-scoped middleware — runs only when the request
  /// path starts with [path].
  ///
  /// Use this to protect route groups without repeating the middleware on every
  /// individual route:
  ///
  /// ```dart
  /// app.mount('/api/*', jwt(secret: env.secret));
  /// app.mount('/public', serveStatic('public'));
  /// ```
  void mount(String path, Middleware m) {
    final rp = _routePrefix;
    final resolved = (rp != null && !path.startsWith(rp))
        ? _normalizePath('$rp$path')
        : path;
    final (regex, _) = _compile(resolved, strict: false, isPrefix: true);
    _routes.add(_Route(
      path: resolved,
      regex: regex,
      paramNames: const [],
      middlewares: [m],
    ));
  }

  // ── Routes ────────────────────────────────────────────────────────────────

  void get(String path, List<Middleware> m, Handler h) =>
      _add('GET', path, h, m);
  void post(String path, List<Middleware> m, Handler h) =>
      _add('POST', path, h, m);
  void put(String path, List<Middleware> m, Handler h) =>
      _add('PUT', path, h, m);
  void patch(String path, List<Middleware> m, Handler h) =>
      _add('PATCH', path, h, m);
  void delete(String path, List<Middleware> m, Handler h) =>
      _add('DELETE', path, h, m);
  void head(String path, List<Middleware> m, Handler h) =>
      _add('HEAD', path, h, m);
  void options(String path, List<Middleware> m, Handler h) =>
      _add('OPTIONS', path, h, m);

  void all(String path, List<Middleware> m, Handler h) {
    for (final method in const [
      'GET',
      'POST',
      'PUT',
      'DELETE',
      'PATCH',
      'HEAD',
      'OPTIONS'
    ]) {
      _add(method, path, h, m);
    }
  }

  /// Registers [h] for every combination of [methods] × [paths].
  ///
  /// Supports any HTTP method string, including non-standard ones like `PURGE`.
  ///
  /// ```dart
  /// // Custom method
  /// app.on(['PURGE'], ['/cache'], [], (c) => c.text('PURGE /cache'));
  ///
  /// // Multiple methods, one path
  /// app.on(['PUT', 'DELETE'], ['/post'], [], (c) => c.text('PUT or DELETE'));
  ///
  /// // One method, multiple paths
  /// app.on(['GET'], ['/hello', '/ja/hello'], [], (c) => c.text('Hello'));
  /// ```
  void on(
    List<String> methods,
    List<String> paths,
    List<Middleware> m,
    Handler h,
  ) {
    for (final method in methods) {
      for (final path in paths) {
        _add(method.toUpperCase(), path, h, m);
      }
    }
  }

  // ── Grouping ──────────────────────────────────────────────────────────────

  /// Creates a [RouteChain] for [prefix], allowing method chaining.
  ///
  /// The optional [builder] preserves backward compatibility with the grouped
  /// router API. Both styles can be combined.
  ///
  /// ```dart
  /// // Chained style
  /// app.route('/hello')
  ///   .get((c) => c.text('GET'))
  ///   .post((c) => c.text('POST'))
  ///   .delete((c) => c.noContent());
  ///
  /// // Legacy builder style (still works)
  /// app.route('/api', (r) {
  ///   r.get('/users', handler);
  /// });
  /// ```
  RouteChain route(String prefix, [void Function(Router r)? builder]) {
    final rp = _routePrefix;
    final full = rp != null
        ? _normalizePath('$rp$prefix')
        : prefix;
    final r = Router._grouped(full, this);
    builder?.call(r);
    return RouteChain._(full, _add);
  }

  Router group(String prefix) {
    final rp = _routePrefix;
    final full = rp != null
        ? _normalizePath('$rp${_norm(prefix)}')
        : _norm(prefix);
    return Router._grouped(full, this);
  }

  // ── Server ────────────────────────────────────────────────────────────────

  Future<void> listen(int port, [void Function()? callback]) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    callback?.call();
    await for (final req in _server!) {
      _dispatch(req);
    }
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }

  // ── Normalizer ──────────────────────────────────────────────────────────────
  static String _normalizePath(String path) {
    if (path.isEmpty) return '/';
    if (!path.startsWith('/')) path = '/$path';
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return path;
  }

  // ── Dispatch ──────────────────────────────────────────────────────────────

  void _dispatch(HttpRequest httpReq) async {
    final method = httpReq.method;
    var path = httpReq.uri.path;

    final req = DartoRequest(httpReq, {});
    final res = DartoResponse(httpReq.response);

    final pipeline = <Middleware>[];
    final matchedRoutesList = <RouteSpec>[];
    _Route? matched;

    for (final route in _routes) {
      if (route.regex == null && route.method == null) {
        pipeline.addAll(route.middlewares);
        continue;
      }
      final match = route.regex?.firstMatch(path);
      if (match == null) continue;
      if (route.method != null && route.method != method) continue;

      if (route.path != null) {
        matchedRoutesList.add(RouteSpec(
          method: route.method ?? 'ALL',
          path: route.path!,
        ));
      }

      for (var i = 0; i < route.paramNames.length; i++) {
        final v = match.group(i + 1);
        if (v != null && v.isNotEmpty) req._params[route.paramNames[i]] = v;
      }

      if (route.handler != null) {
        pipeline.addAll(route.middlewares);
        matched = route;
        break;
      } else {
        pipeline.addAll(route.middlewares);
      }
    }

    final c = Context(req, res);
    c._matchedRoutes = matchedRoutesList;
    if (matched != null) {
      c._routePath = matched.path;
      c._baseRoutePath = matched.groupPrefix;
      c._basePath = _resolveBasePath(matched.groupPrefix, path);
    }
    final Response result;

    if (matched == null) {
      await _run(pipeline, (c) => null, c);

      if (c._response != null) {
        if (!res.finished) await c._response!.writeTo(httpReq.response);
        return;
      }

      result = _notFoundHandler != null
          ? await _safe(() => _notFoundHandler!(c)) ?? c.notFound()
          : c.notFound();
    } else {
      try {
        result = await _run(pipeline, matched.handler!, c);
        if (!res.finished) await result.writeTo(httpReq.response);
        return;
      } catch (e, st) {
        final err = DartoError(e, st);
        final r = _onErrorHandler != null
            ? await _safe(() => _onErrorHandler!(err, c))
            : Response.json({'error': e.toString()}, status: 500);
        if (!res.finished) await r?.writeTo(httpReq.response);
        return;
      }
    }

    if (!res.finished) await result.writeTo(httpReq.response);
  }

  // ── Pipeline ──────────────────────────────────────────────────────────────

  static Future<Response> _run(
    List<Middleware> middlewares,
    Handler handler,
    Context c,
  ) async {
    Future<void> dispatch(int i) async {
      if (c._response != null) return;

      if (i >= middlewares.length) {
        c._response ??= await handler(c);
        return;
      }

      await middlewares[i](c, () => dispatch(i + 1));
    }

    await dispatch(0);

    return c._response ??
        Response.json({'error': 'No response returned'}, status: 500);
  }

  static Future<Response?> _safe(FutureOr<Response>? Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      return Response.json({'error': e.toString()}, status: 500);
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  void _add(String method, String path, Handler h, List<Middleware> m) {
    final rp = _routePrefix;
    if (rp != null && !path.startsWith(rp)) {
      path = _normalizePath('$rp$path');
    }
    final (regex, names) = _compile(path, strict: strict);
    _routes.add(_Route(
      path: path,
      regex: regex,
      paramNames: names,
      method: method,
      middlewares: m,
      handler: h,
    ));
  }

  // void _mount(String prefix, Router router) {
  //   for (final r in router._routes) {
  //     if (r.path == null) {
  //       _routes.add(r);
  //       continue;
  //     }
  //     final seg = r.path!.startsWith('/') ? r.path!.substring(1) : r.path!;
  //     final newPath =
  //         _normalizePath(prefix.endsWith('/') ? '$prefix$seg' : '$prefix/$seg');
  //     final (regex, names) = _compile(newPath, strict: strict);
  //     _routes.add(_Route(
  //       path: newPath,
  //       regex: regex,
  //       paramNames: names,
  //       method: r.method,
  //       middlewares: r.middlewares,
  //       handler: r.handler,
  //     ));
  //   }
  // }

  static String _norm(String s) =>
      s.isNotEmpty && !s.startsWith('/') ? '/$s' : s;

  static (RegExp, List<String>) _compile(
    String path, {
    required bool strict,
    bool isPrefix = false,
  }) {
    final paramNames = <String>[];

    String pattern = path;

    // Named wildcard: *path
    pattern = pattern.replaceAllMapped(
      RegExp(r'\*([a-zA-Z_]\w*)'),
      (m) {
        final name = m.group(1)!;
        paramNames.add(name);
        return '(.*)';
      },
    );

    // Unnamed wildcard: *
    pattern = pattern.replaceAllMapped(
      RegExp(r'\*'),
      (m) {
        paramNames.add('wildcard');
        return '(.*)';
      },
    );

    // Optional params: /:id?
    pattern = pattern.replaceAllMapped(
      RegExp(r'/:(\w+)\?'),
      (m) {
        final name = m.group(1)!;
        paramNames.add(name);
        return '(?:/([^/]+))?';
      },
    );

    // Regex params: /:id(\d+)
    pattern = pattern.replaceAllMapped(
      RegExp(r'/:(\w+)\(([^)]+)\)'),
      (m) {
        final name = m.group(1)!;
        final regex = m.group(2)!;
        paramNames.add(name);
        return '/($regex)';
      },
    );

    // Normal params: /:id
    pattern = pattern.replaceAllMapped(
      RegExp(r'/:(\w+)'),
      (m) {
        final name = m.group(1)!;
        paramNames.add(name);
        return '/([^/]+)';
      },
    );

    final finalPattern = isPrefix
        ? '^$pattern(?:/.*)?'
        : strict
            ? '^$pattern\$'
            : '^$pattern/?\$';

    return (RegExp(finalPattern), paramNames);
  }

  static String _resolveBasePath(String? prefix, String actualPath) {
    if (prefix == null || prefix == '/') return '/';
    final prefixSegmentCount =
        prefix.split('/').where((s) => s.isNotEmpty).length;
    if (prefixSegmentCount == 0) return '/';
    final segments =
        actualPath.split('/').where((s) => s.isNotEmpty).toList();
    if (prefixSegmentCount > segments.length) return actualPath;
    return '/${segments.take(prefixSegmentCount).join('/')}';
  }

}
