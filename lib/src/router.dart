part of 'darto_base.dart';

class Router {
  final Map<String, List<MapEntry<RegExp, Map<String, dynamic>>>> _routes = {};
  final Map<String, List<ParamMiddleware>> _paramCallbacks = {};

  void get(String path, dynamic first, [dynamic second, dynamic third]) =>
      _addRoute('GET', path, first, second, third);
  void post(String path, dynamic first, [dynamic second, dynamic third]) =>
      _addRoute('POST', path, first, second, third);
  void put(String path, dynamic first, [dynamic second, dynamic third]) =>
      _addRoute('PUT', path, first, second, third);
  void delete(String path, dynamic first, [dynamic second, dynamic third]) =>
      _addRoute('DELETE', path, first, second, third);

  void param(String name, ParamMiddleware callback) {
    if (!_paramCallbacks.containsKey(name)) {
      _paramCallbacks[name] = [];
    }
    _paramCallbacks[name]!.add(callback);
  }

  void _addRoute(String method, String path, dynamic first,
      [dynamic second, dynamic third]) {
    // Se a rota não for a raiz ("/"), remove a barra final para evitar duplicação.
    if (path != "/" && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    final paramNames = <String>[];
    String regexPattern = path.replaceAllMapped(RegExp(r'/:(\w+)\?'), (match) {
      paramNames.add(match.group(1)!);
      return '(?:/([^/]+))?';
    });
    regexPattern = regexPattern.replaceAllMapped(RegExp(r'/:(\w+)'), (match) {
      paramNames.add(match.group(1)!);
      return '/([^/]+)';
    });
    regexPattern =
        regexPattern.replaceAllMapped(RegExp(r'/\*'), (match) => '(?:/(.*))?');

    // Remove a barra inicial, se houver.
    if (regexPattern.startsWith('/')) {
      regexPattern = regexPattern.substring(1);
    }

    // Se o regexPattern for vazio (rota raiz), use expressão que aceita com ou sem barra.
    final regexPath = regexPattern.isEmpty
        ? RegExp('^/?\$')
        : RegExp('^' + regexPattern + '/?\$');

    final List<dynamic> handlers = [];
    if (first is Middleware || first is RouteHandler) {
      handlers.add(first);
    }
    if (second != null) {
      handlers.add(second);
    }
    if (third != null) {
      handlers.add(third);
    }
    if (handlers.isEmpty) {
      throw ArgumentError("Route must have at least one handler.");
    }
    _routes.putIfAbsent(method, () => []).add(
          MapEntry(regexPath, {
            'handlers': handlers,
            'paramNames': paramNames,
            'paramCallbacks': _paramCallbacks
          }),
        );
  }

  Route route(String path) => Route(path, this);

  void all(String path, dynamic first, [dynamic second, dynamic third]) {
    final methods = [
      'GET',
      'POST',
      'PUT',
      'DELETE',
      'PATCH',
      'HEAD',
      'OPTIONS',
      'TRACE'
    ];
    for (var method in methods) {
      _addRoute(method, path, first, second, third);
    }
  }

  void on(dynamic methods, dynamic paths, dynamic first,
      [dynamic second, dynamic third]) {
    if (methods is! List && methods is! String) {
      throw ArgumentError('Methods parameter must be a String or List<String>');
    }
    if (paths is! List && paths is! String) {
      throw ArgumentError('Paths parameter must be a String or List<String>');
    }
    final List<String> methodsList =
        methods is String ? [methods] : List<String>.from(methods);
    final List<String> pathsList =
        paths is String ? [paths] : List<String>.from(paths);
    for (var method in methodsList) {
      for (var path in pathsList) {
        _addRoute(method.toUpperCase(), path, first, second, third);
      }
    }
  }
}

class Route {
  final String path;
  final Router router;
  final List<Middleware> _commonHandlers = [];

  Route(this.path, this.router);

  Route all(Middleware handler) {
    _commonHandlers.add(handler);
    return this;
  }

  Route get(Middleware handler) {
    final handlers = List<Middleware>.from(_commonHandlers)..add(handler);
    router._addRouteChain('GET', path, handlers);
    return this;
  }

  Route post(Middleware handler) {
    final handlers = List<Middleware>.from(_commonHandlers)..add(handler);
    router._addRouteChain('POST', path, handlers);
    return this;
  }

  Route put(Middleware handler) {
    final handlers = List<Middleware>.from(_commonHandlers)..add(handler);
    router._addRouteChain('PUT', path, handlers);
    return this;
  }

  Route delete(Middleware handler) {
    final handlers = List<Middleware>.from(_commonHandlers)..add(handler);
    router._addRouteChain('DELETE', path, handlers);
    return this;
  }
}

extension on Router {
  void _addRouteChain(String method, String path, List<Middleware> handlers) {
    // Se a rota não for a raiz ("/"), remove a barra final para evitar duplicação.
    if (path != "/" && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    final paramNames = <String>[];
    String regexPattern = path.replaceAllMapped(RegExp(r'/:(\w+)\?'), (match) {
      paramNames.add(match.group(1)!);
      return '(?:/([^/]+))?';
    });
    regexPattern = regexPattern.replaceAllMapped(RegExp(r'/:(\w+)'), (match) {
      paramNames.add(match.group(1)!);
      return '/([^/]+)';
    });
    regexPattern =
        regexPattern.replaceAllMapped(RegExp(r'/\*'), (match) => '(?:/(.*))?');

    // Remove a barra inicial, se houver.
    if (regexPattern.startsWith('/')) {
      regexPattern = regexPattern.substring(1);
    }

    // Se o regexPattern for vazio (rota raiz), use expressão que aceita com ou sem barra.
    final regexPath = regexPattern.isEmpty
        ? RegExp('^/?\$')
        : RegExp('^' + regexPattern + '/?\$');

    if (handlers.isEmpty) {
      throw ArgumentError("Route must have at least one handler.");
    }
    _routes.putIfAbsent(method, () => []).add(
          MapEntry(regexPath, {
            'handlers': handlers,
            'paramNames': paramNames,
            'paramCallbacks': _paramCallbacks
          }),
        );
  }
}
