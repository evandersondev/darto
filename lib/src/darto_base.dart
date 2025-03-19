import 'dart:io';

import 'package:darto/darto.dart';
import 'package:darto/src/darto_logger.dart';
import 'package:darto/src/types.dart';
import 'package:path/path.dart' as p;

class Darto {
  final Logger _logger;
  final bool _snakeCase;
  final List<String> _staticFolders = [];

  Darto({Logger? logger, bool? snakeCase})
      : _logger = logger ?? Logger(),
        _snakeCase = snakeCase ?? false;

  final Map<String, List<MapEntry<RegExp, Map<String, dynamic>>>> _routes = {};
  final List<Middleware> _globalMiddlewares = [];
  Map<String, String> _corsOptions = {}; // Configurações de CORS

  void get(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('GET', path, first, second, third);
  }

  void post(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('POST', path, first, second, third);
  }

  void put(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('PUT', path, first, second, third);
  }

  void delete(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('DELETE', path, first, second, third);
  }

  void use(dynamic pathOrMiddleware, [dynamic second]) {
    if (pathOrMiddleware is Middleware) {
      // Middleware global
      _globalMiddlewares.add(pathOrMiddleware);
    } else if (pathOrMiddleware is Router && second == null) {
      // Adiciona todas as rotas do Router sem prefixo
      _addRouterRoutes('', pathOrMiddleware);
    } else if (pathOrMiddleware is String && second is Middleware) {
      // Middleware específico de rota
      _addRouteMiddleware(pathOrMiddleware, second);
    } else if (pathOrMiddleware is String && second is Router) {
      // Prefixo de rota e um Router: todas as rotas deste Router terão o prefixo
      _addRouterRoutes(pathOrMiddleware, second);
    } else {
      throw ArgumentError('Invalid arguments for use method');
    }
  }

  void static(String path) {
    _staticFolders.add(path);
    _addStaticRoute(path);
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
      throw ArgumentError("A rota deve ter pelo menos um handler.");
    }

    _routes.putIfAbsent(method, () => []).add(
          MapEntry(regexPath, {'handlers': handlers, 'paramNames': paramNames}),
        );
  }

  void _addRouteMiddleware(String path, Middleware middleware) {
    final paramNames = <String>[];
    final regexPath = RegExp(
      '^' +
          path.replaceAllMapped(RegExp(r':(\w+)'), (match) {
            paramNames.add(match.group(1)!);
            return '([^/]+)';
          }) +
          r'$',
    );

    _routes.putIfAbsent('USE', () => []).add(
          MapEntry(regexPath, {
            'handlers': [middleware],
            'paramNames': paramNames
          }),
        );
  }

  void _addStaticRoute(String folder) {
    final regexPath = RegExp('^/$folder/(.*)');
    _routes.putIfAbsent('GET', () => []).add(
          MapEntry(regexPath, {
            'handlers': [
              (Request req, Response res) async {
                final relativePath = req.uri.path.replaceFirst('/$folder/', '');
                final filePath = p.normalize(p.absolute(folder, relativePath));

                if (await File(filePath).exists()) {
                  res.sendFile(filePath);
                } else {
                  res
                      .status(HttpStatus.notFound)
                      .send({'error': 'File not found'});
                }
              }
            ],
            'paramNames': <String>[]
          }),
        );
  }

  // Updated _addRouterRoutes to remove leading slash from the route pattern before concatenating.
  void _addRouterRoutes(String prefix, Router router) {
    router.routes.forEach((method, routeEntries) {
      for (final entry in routeEntries) {
        final RegExp originalRegex = entry.key;
        String pattern = originalRegex.pattern;

        // Remove beginning '^' and ending '$'
        if (pattern.startsWith('^')) pattern = pattern.substring(1);
        if (pattern.endsWith(r'$'))
          pattern = pattern.substring(0, pattern.length - 1);

        String newPattern;
        if (pattern == '/' || pattern.trim() == '') {
          if (prefix.isEmpty) {
            newPattern = r'^/?$';
          } else {
            String base = prefix;
            if (base.endsWith('/')) {
              base = base.substring(0, base.length - 1);
            }
            newPattern = '^' + base + r'/?$';
          }
        } else {
          // Remove the leading slash from the pattern if it exists
          if (pattern.startsWith('/')) pattern = pattern.substring(1);
          String normalizedPrefix = prefix;
          if (normalizedPrefix.isNotEmpty && !normalizedPrefix.endsWith('/')) {
            normalizedPrefix += '/';
          }
          newPattern = '^' + normalizedPrefix + pattern + r'$';
        }

        final newRegex = RegExp(newPattern);
        _routes.putIfAbsent(method, () => []).add(
              MapEntry(newRegex, entry.value),
            );
      }
    });
  }

  void useCors({
    String origin = '*',
    String methods = 'GET, POST, PUT, DELETE, OPTIONS',
    String headers = 'Content-Type',
  }) {
    _corsOptions = {
      'Access-Control-Allow-Origin': origin,
      'Access-Control-Allow-Methods': methods,
      'Access-Control-Allow-Headers': headers,
    };
  }

  void listen(int port, [void Function()? callback]) async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    if (_logger.isActive(LogLevel.info)) {
      DartoLogger.log('Server started on port $port', LogLevel.info);
    }
    callback?.call();

    await for (HttpRequest request in server) {
      final method = request.method;
      final path = request.uri.path;

      if (_logger.isActive(LogLevel.access)) {
        DartoLogger.log(
          '[$method $path] - IP: ${request.connectionInfo?.remoteAddress.address}',
          LogLevel.access,
        );
      }

      final req = Request(request, {}, _logger);
      final res =
          Response(request.response, _logger, _snakeCase, _staticFolders);

      final middlewares = _globalMiddlewares.toList();
      final routeEntries = _routes[method] ?? [];
      bool handled = false;

      for (var entry in _routes['USE'] ?? []) {
        final match = entry.key.firstMatch(path);
        if (match != null) {
          middlewares.addAll(entry.value['handlers'].cast<Middleware>());
        }
      }

      for (var entry in routeEntries) {
        final match = entry.key.firstMatch(path);
        if (match != null) {
          // Cast paramNames to List<String> to avoid type errors.
          final params = _extractRouteParams(
            (entry.value['paramNames'] as List).cast<String>(),
            match,
          );
          req.params.addAll(params);
          final handlers = entry.value['handlers'];
          middlewares.addAll(handlers.whereType<Middleware>());
          middlewares.add((req, res, next) {
            final handler = handlers.last as RouteHandler;
            handler(req, res);
          });
          handled = true;
          break;
        }
      }

      if (!handled) {
        _applyCors(res);
        res.status(HttpStatus.notFound).send({'error': 'Route not found'});
        continue;
      }

      _executeMiddlewares(req, res, middlewares);
    }
  }

  void _executeMiddlewares(
      Request req, Response res, List<Middleware> middlewares) {
    int index = 0;
    void next() {
      if (index < middlewares.length) {
        final middleware = middlewares[index++];
        middleware(req, res, next);
      }
    }

    next();
  }

  Map<String, String> _extractRouteParams(
      List<String> paramNames, Match match) {
    final params = <String, String>{};
    for (var i = 0; i < paramNames.length; i++) {
      params[paramNames[i]] = match.group(i + 1) ?? '';
    }
    return params;
  }

  void _applyCors(Response res) {
    _corsOptions.forEach((key, value) {
      res.res.headers.set(key, value);
    });
  }
}
