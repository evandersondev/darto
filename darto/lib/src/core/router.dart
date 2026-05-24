part of 'darto_base.dart';

// ── RouteChain ────────────────────────────────────────────────────────────────

/// Fluent route builder returned by [Darto.route] and [Router.route].
///
/// ```dart
/// app.route('/hello')
///   .get((c) => c.text('GET'))
///   .post((c) => c.text('POST'))
///   .on(['PUT', 'DELETE'], (c) => c.noContent());
/// ```
class RouteChain {
  final String _path;
  final void Function(String, String, Handler, List<Middleware>) _register;

  RouteChain._(this._path, this._register);

  RouteChain get(List<Middleware> m, Handler h) => _do('GET', h, m);
  RouteChain post(List<Middleware> m, Handler h) => _do('POST', h, m);
  RouteChain put(List<Middleware> m, Handler h) => _do('PUT', h, m);
  RouteChain patch(List<Middleware> m, Handler h) => _do('PATCH', h, m);
  RouteChain delete(List<Middleware> m, Handler h) => _do('DELETE', h, m);
  RouteChain head(List<Middleware> m, Handler h) => _do('HEAD', h, m);
  RouteChain options(List<Middleware> m, Handler h) => _do('OPTIONS', h, m);

  /// Registers [h] for each method in [methods] on this route's path.
  RouteChain on(List<String> methods, List<Middleware> m, Handler h) {
    for (final method in methods) {
      _register(method.toUpperCase(), _path, h, m);
    }
    return this;
  }

  RouteChain _do(String method, Handler h, List<Middleware> m) {
    _register(method, _path, h, m);
    return this;
  }
}

// ── Router ────────────────────────────────────────────────────────────────────

class Router {
  final List<_Route> _routes = [];
  final String? _prefix;
  final Darto? _owner;

  Router()
      : _prefix = null,
        _owner = null;
  Router._grouped(this._prefix, this._owner);

  // ── Middleware ────────────────────────────────────────────────────────────

  /// Registers [m] as a global middleware on this router.
  void use(Middleware m) {
    _push(_Route(middlewares: [m]));
  }

  /// Registers [m] as a path-scoped middleware on this router.
  void mount(String path, Middleware m) {
    final full = _full(path);
    if (full == null) {
      _push(_Route(middlewares: [m]));
      return;
    }
    final (regex, names) =
        Darto._compile(full, strict: _owner?.strict ?? false);
    _push(_Route(path: full, regex: regex, paramNames: names, middlewares: [m]));
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
  /// router.on(['PURGE'], ['/cache'], [], (c) => c.text('PURGE /cache'));
  ///
  /// // Multiple methods, one path
  /// router.on(['PUT', 'DELETE'], ['/post'], [], (c) => c.text('PUT or DELETE'));
  ///
  /// // One method, multiple paths
  /// router.on(['GET'], ['/hello', '/ja/hello'], [], (c) => c.text('Hello'));
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

  // ── Grouping ─────────────────────────────────────────────────────────────

  Router group(String prefix) {
    final newPrefix = _join(_prefix ?? '', prefix);
    return Router._grouped(newPrefix, _owner);
  }

  RouteChain route(String prefix, [void Function(Router r)? builder]) {
    final newPrefix = _join(_prefix ?? '', prefix);
    final child = Router._grouped(newPrefix, _owner);
    builder?.call(child);
    final fullPath = Darto._normalizePath(newPrefix);
    // Bypass _full() to avoid double-prefixing — register directly via _push.
    return RouteChain._(fullPath, (method, path, h, m) {
      final (regex, names) =
          Darto._compile(path, strict: _owner?.strict ?? false);
      _push(_Route(
        path: path,
        regex: regex,
        paramNames: names,
        method: method,
        middlewares: m,
        handler: h,
      ));
    });
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  void _add(String method, String path, Handler h, List<Middleware> m) {
    if (path != '/' && path.endsWith('/'))
      path = path.substring(0, path.length - 1);
    final full = Darto._normalizePath(_full(path) ?? path);
    final (regex, names) =
        Darto._compile(full, strict: _owner?.strict ?? false);
    _push(_Route(
        path: full,
        regex: regex,
        paramNames: names,
        method: method,
        middlewares: m,
        handler: h,
        groupPrefix: _prefix));
  }

  String? _full(String? path) {
    if (_prefix == null) return path;
    if (path == null) return _prefix;

    return _join(_prefix!, path);
  }

  String _join(String a, String b) {
    if (a.isEmpty) return b.startsWith('/') ? b : '/$b';

    if (a.endsWith('/')) a = a.substring(0, a.length - 1);
    if (!b.startsWith('/')) b = '/$b';

    return '$a$b';
  }

  void _push(_Route route) {
    if (_owner != null) {
      _owner!._routes.add(route);
    } else {
      _routes.add(route);
    }
  }
}
