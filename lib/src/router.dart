import 'package:darto/src/types.dart';

import 'request.dart';
import 'response.dart';

typedef ParamMiddleware = void Function(
    Request req, Response res, Next next, String value);

class Router {
  // Armazena as rotas registradas
  final Map<String, List<MapEntry<RegExp, Map<String, dynamic>>>> routes = {};

  // Armazena os callbacks de parâmetro
  final Map<String, List<ParamMiddleware>> paramCallbacks = {};

  void get(String path, dynamic first, [dynamic second, dynamic third]) =>
      _addRoute('GET', path, first, second, third);
  void post(String path, dynamic first, [dynamic second, dynamic third]) =>
      _addRoute('POST', path, first, second, third);
  void put(String path, dynamic first, [dynamic second, dynamic third]) =>
      _addRoute('PUT', path, first, second, third);
  void delete(String path, dynamic first, [dynamic second, dynamic third]) =>
      _addRoute('DELETE', path, first, second, third);

  // Registra callbacks para um parâmetro específico
  void param(String name, ParamMiddleware callback) {
    if (!paramCallbacks.containsKey(name)) {
      paramCallbacks[name] = [];
    }
    paramCallbacks[name]!.add(callback);
  }

  void _addRoute(String method, String path, dynamic first,
      [dynamic second, dynamic third]) {
    final paramNames = <String>[];
    final regexPath = RegExp(
      '^' +
          path.replaceAllMapped(RegExp(r':(\w+)'), (match) {
            paramNames.add(match.group(1)!);
            return '([^/]+)';
          }) +
          r'$',
    );

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

    // Ao adicionar uma rota, anexa os callbacks de parâmetros cadastrados
    routes.putIfAbsent(method, () => []).add(
          MapEntry(regexPath, {
            'handlers': handlers,
            'paramNames': paramNames,
            'paramCallbacks': paramCallbacks // anexa mapa de callbacks
          }),
        );
  }

  // Para permitir construção encadeada de rotas (como no Express)
  Route route(String path) => Route(path, this);
}

class Route {
  final String path;
  final Router router;
  final List<Middleware> _commonHandlers = [];

  Route(this.path, this.router);

  // Executa para todos os verbos HTTP (middleware específico da rota)
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
  // Método auxiliar para registro de rota via construção encadeada
  void _addRouteChain(String method, String path, List<Middleware> handlers) {
    final paramNames = <String>[];
    final regexPath = RegExp(
      '^' +
          path.replaceAllMapped(RegExp(r':(\w+)'), (match) {
            paramNames.add(match.group(1)!);
            return '([^/]+)';
          }) +
          r'$',
    );
    if (handlers.isEmpty) {
      throw ArgumentError("Route must have at least one handler.");
    }
    // Anexa os callbacks de parâmetros também
    routes.putIfAbsent(method, () => []).add(
          MapEntry(regexPath, {
            'handlers': handlers,
            'paramNames': paramNames,
            'paramCallbacks': paramCallbacks
          }),
        );
  }
}
