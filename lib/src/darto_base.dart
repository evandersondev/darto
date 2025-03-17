import 'dart:io';

import 'package:darto/src/darto_logger.dart';
import 'package:darto/src/logger.dart';
import 'package:darto/src/request.dart';
import 'package:darto/src/response.dart';
import 'package:darto/src/types.dart';
import 'package:path/path.dart' as p;

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
        MapEntry(regexPath, {'handlers': handlers, 'paramNames': paramNames}));
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

    _routes.putIfAbsent('USE', () => []).add(MapEntry(regexPath, {
          'handlers': [middleware],
          'paramNames': paramNames
        }));
  }

  void serveStatic(String folder) {
    _staticFolder = folder;
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
          middlewares.addAll(entry.value['handlers'].cast<Middleware>());
        }
      }

      for (var entry in routeEntries) {
        final match = entry.key.firstMatch(path);
        if (match != null) {
          final params = _extractRouteParams(entry.value['paramNames'], match);
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
