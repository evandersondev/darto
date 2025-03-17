import 'dart:io';

import 'package:darto/src/darto_logger.dart';
import 'package:darto/src/logger.dart';
import 'package:darto/src/request.dart';
import 'package:darto/src/response.dart';
import 'package:path/path.dart' as p;

typedef Middleware = Function(Request req, Response res, Function() next);
typedef RouteHandler = Function(Request req, Response res);

class Darto {
  final Logger _logger;
  final bool _snakeCase;

  Darto({Logger? logger, bool? snakeCase})
      : _logger = logger ?? Logger(),
        _snakeCase = snakeCase ?? false;

  final Map<String, List<MapEntry<RegExp, Map<String, dynamic>>>> _routes = {};
  final List<Middleware> _globalMiddlewares = [];
  String? _staticFolder;
  Map<String, String> _corsOptions = {}; // Configurações de CORS

  void get(String path, RouteHandler handler,
          [List<Middleware>? middlewares]) =>
      _addRoute('GET', path, handler, middlewares);
  void post(String path, RouteHandler handler,
          [List<Middleware>? middlewares]) =>
      _addRoute('POST', path, handler, middlewares);
  void put(String path, RouteHandler handler,
          [List<Middleware>? middlewares]) =>
      _addRoute('PUT', path, handler, middlewares);
  void delete(String path, RouteHandler handler,
          [List<Middleware>? middlewares]) =>
      _addRoute('DELETE', path, handler, middlewares);

  void use(dynamic pathOrMiddleware, [Middleware? middleware]) {
    if (pathOrMiddleware is String && middleware != null) {
      // Middleware específico de rota
      _addRouteMiddleware(pathOrMiddleware, middleware);
    } else if (pathOrMiddleware is Middleware) {
      // Middleware global
      _globalMiddlewares.add(pathOrMiddleware);
    } else if (pathOrMiddleware is String) {
      // Configurar arquivos estáticos
      _staticFolder = pathOrMiddleware;
    } else {
      throw ArgumentError('Invalid arguments for use method');
    }
  }

  void _addRoute(String method, String path, RouteHandler handler,
      [List<Middleware>? middlewares]) {
    final paramNames = <String>[];
    final regexPath = RegExp(
      '^' +
          path.replaceAllMapped(RegExp(r':(\w+)'), (match) {
            paramNames.add(match.group(1)!);
            return '([^/]+)';
          }) +
          r'$',
    );

    final routeEntry = {
      'handler': handler,
      'paramNames': paramNames,
    };

    if (middlewares != null) {
      routeEntry['middlewares'] = middlewares;
    }

    _routes.putIfAbsent(method, () => []).add(MapEntry(regexPath, routeEntry));
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

    final routeEntry = MapEntry(regexPath, {
      'middleware': middleware,
      'paramNames': paramNames,
    });

    _routes.putIfAbsent('USE', () => []).add(routeEntry);
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
      final startTime = DateTime.now();

      if (_logger.isActive(LogLevel.access)) {
        DartoLogger.log(
            '[$method $path] - IP: ${request.connectionInfo?.remoteAddress.address}',
            LogLevel.access);
      }

      // Verifica se está servindo arquivos estáticos antes das rotas
      if (_staticFolder != null && await _serveFile(request, path)) {
        if (_logger.isActive(LogLevel.info)) {
          final duration = DateTime.now().difference(startTime).inMilliseconds;
          DartoLogger.log(
              '[$method $path] - Status: 200 - ${duration}ms - User-Agent: ${request.headers.value('user-agent')}',
              LogLevel.info);
        }
        continue;
      }

      final req = Request(request, {}, _logger);
      final res = Response(request.response, _logger, _snakeCase);

      final middlewares = _globalMiddlewares.toList();
      final routeEntries = _routes[method] ?? [];
      bool handled = false;

      for (var entry in _routes['USE'] ?? []) {
        final match = entry.key.firstMatch(path);
        if (match != null) {
          middlewares.add(entry.value['middleware']);
        }
      }

      for (var entry in routeEntries) {
        final match = entry.key.firstMatch(path);
        if (match != null) {
          final params = _extractRouteParams(
              entry.key, entry.value['paramNames'] ?? [], match);
          req.params.addAll(params);
          if (entry.value['middlewares'] != null) {
            middlewares.addAll(entry.value['middlewares']);
          }
          middlewares.add((req, res, next) async {
            await entry.value['handler'](req, res);
            await next();
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

      await _executeMiddlewares(req, res, middlewares);
    }
  }

  Future<void> _executeMiddlewares(
      Request req, Response res, List<Middleware> middlewares) async {
    int index = 0;

    Future<void> next() async {
      if (index < middlewares.length) {
        final middleware = middlewares[index++];
        await middleware(req, res, next);
      }
    }

    await next();
  }

  Map<String, String> _extractRouteParams(
      RegExp pattern, List<String> paramNames, Match match) {
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

  Future<bool> _serveFile(HttpRequest request, String path) async {
    final filePath = p.join('$_staticFolder$path');
    final file = File(filePath);

    if (await file.exists()) {
      request.response.headers.contentType = _getContentType(filePath);
      await file.openRead().pipe(request.response);
      if (_logger.isActive(LogLevel.info)) {
        final duration = DateTime.now()
            .difference(request.headers.date ?? DateTime.now())
            .inMilliseconds;
        DartoLogger.log(
            '[GET $filePath] - Status: 200 - ${duration}ms - User-Agent: ${request.headers.value('user-agent')}',
            LogLevel.info);
      }
      return true;
    }

    return false;
  }

  ContentType _getContentType(String filePath) {
    final extension = p.extension(filePath).toLowerCase();
    switch (extension) {
      case '.html':
        return ContentType.html;
      case '.css':
        return ContentType('text', 'css');
      case '.js':
        return ContentType('application', 'javascript');
      case '.png':
        return ContentType('image', 'png');
      case '.jpg':
      case '.jpeg':
        return ContentType('image', 'jpeg');
      case '.gif':
        return ContentType('image', 'gif');
      case '.svg':
        return ContentType('image', 'svg+xml');
      case '.json':
        return ContentType.json;
      default:
        return ContentType.text;
    }
  }
}

/// 📌 **Classe Router**
///
/// Esta classe é responsável por gerenciar as rotas da aplicação.
class Router {
  final Map<String, List<MapEntry<RegExp, Map<String, dynamic>>>> routes = {};

  void get(String path, RouteHandler handler,
          [List<Middleware>? middlewares]) =>
      _addRoute('GET', path, handler, middlewares);
  void post(String path, RouteHandler handler,
          [List<Middleware>? middlewares]) =>
      _addRoute('POST', path, handler, middlewares);
  void put(String path, RouteHandler handler,
          [List<Middleware>? middlewares]) =>
      _addRoute('PUT', path, handler, middlewares);
  void delete(String path, RouteHandler handler,
          [List<Middleware>? middlewares]) =>
      _addRoute('DELETE', path, handler, middlewares);

  void _addRoute(String method, String path, RouteHandler handler,
      [List<Middleware>? middlewares]) {
    final paramNames = <String>[];
    final regexPath = RegExp(
      '^' +
          path.replaceAllMapped(RegExp(r':(\w+)'), (match) {
            paramNames.add(match.group(1)!);
            return '([^/]+)';
          }) +
          r'$',
    );

    final routeEntry = {
      'handler': handler,
      'paramNames': paramNames,
    };

    if (middlewares != null) {
      routeEntry['middlewares'] = middlewares;
    }

    routes.putIfAbsent(method, () => []).add(MapEntry(regexPath, routeEntry));
  }
}
