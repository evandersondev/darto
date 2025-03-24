import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:darto/darto.dart';
import 'package:darto/src/darto_logger.dart';
import 'package:darto/src/types.dart';

class Darto {
  final Logger _logger;
  final bool _snakeCase;
  final List<String> _staticFolders = [];
  final Map<String, dynamic> _settings = {};

  Darto({Logger? logger, bool? snakeCase})
      : _logger = logger ?? Logger(),
        _snakeCase = snakeCase ?? false;

  final Map<String, List<MapEntry<RegExp, Map<String, dynamic>>>> _routes = {};
  final List<Middleware> _globalMiddlewares = [];
  Map<String, String> _corsOptions = {};

  // Lista de middlewares de erro (incluindo os de timeout)
  final List<Timeout> _errorMiddlewares = [];

  /// Armazena um valor global de configuração.
  void set(String key, dynamic value) {
    _settings[key] = value;
  }

  /// Método GET com comportamento duplo:
  /// - Se chamado com apenas uma string, pode ser estendido para buscar configurações.
  /// - Se chamado com handlers, registra uma rota GET.
  ///
  /// Example:
  /// ```dart
  /// app.get('/hello', (Request req, Response res) {
  ///   res.send('Hello, World!');
  /// });
  /// ```
  dynamic get(String path, [dynamic first, dynamic second, dynamic third]) {
    if (first == null) {
      return _settings[path];
    } else {
      _addRoute('GET', path, first, second, third);
    }
  }

  /// Registra uma rota POST.
  void post(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('POST', path, first, second, third);
  }

  /// Registra uma rota PUT.
  void put(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('PUT', path, first, second, third);
  }

  /// Registra uma rota DELETE.
  void delete(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('DELETE', path, first, second, third);
  }

  /// Registra middlewares, sub-rotas ou arquivos estáticos.
  ///
  /// Se o primeiro parâmetro for uma função compatível com [Timeout],
  /// ela é registrada como um middleware de tratamento de erros (ex.: timeout).
  ///
  /// Além disso, se for passado apenas um parâmetro do tipo String, este é tratado
  /// como uma pasta estática.
  void use(dynamic pathOrMiddleware, [dynamic second]) {
    if (pathOrMiddleware is Timeout && second == null) {
      // Trata como middleware de erro (timeout e outros)
      _errorMiddlewares.add(pathOrMiddleware);
    } else if (pathOrMiddleware is Middleware) {
      _globalMiddlewares.add(pathOrMiddleware);
    } else if (pathOrMiddleware is Router && second == null) {
      _addRouterRoutes('', pathOrMiddleware);
    } else if (pathOrMiddleware is String && second == null) {
      // Se for apenas uma string, chame static() explicitamente.
      static(pathOrMiddleware);
    } else if (pathOrMiddleware is String && second is Middleware) {
      _addRouteMiddleware(pathOrMiddleware, second);
    } else if (pathOrMiddleware is String && second is Router) {
      _addRouterRoutes(pathOrMiddleware, second);
    } else {
      throw ArgumentError('Invalid arguments for use method');
    }
  }

  /// Define pasta para arquivos estáticos.
  void static(String path) {
    _staticFolders.add(path);
    _addStaticRoute(path);
  }

  /// Define um timeout global para as requisições em milissegundos.
  ///
  /// Exemplo:
  /// ```dart
  /// app.timeout(5000);
  /// ```
  void timeout(int milliseconds) {
    // Armazena o valor de timeout nas configurações
    set('timeout', milliseconds);

    // Middleware que seta o valor de timeout em req.timeout e dispara erro caso ultrapasse o tempo.
    timeoutMiddleware(Request req, Response res, Next next) {
      // Atribui o valor de timeout à requisição
      req.timeout = milliseconds;

      Timer timer = Timer(Duration(milliseconds: milliseconds), () {
        // Ao disparar o timeout, marcamos a requisição como "timedOut"
        req.timedOut = true;
        if (!res.finished) {
          _executeErrorMiddlewares(Exception("Request timed out"), req, res);
        }
      });

      // Quando a resposta for finalizada, cancela o timer para evitar disparos indevidos
      req.onResponseFinished = () {
        timer.cancel();
      };

      next();
    }

    // Adiciona o middleware de timeout ao início dos middlewares globais
    _globalMiddlewares.insert(0, timeoutMiddleware);
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
              (Request req, Response res, Next next) async {
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

  void _addRouterRoutes(String prefix, Router router) {
    router.routes.forEach((method, routeEntries) {
      for (final entry in routeEntries) {
        final RegExp originalRegex = entry.key;
        String pattern = originalRegex.pattern;
        if (pattern.startsWith('^')) pattern = pattern.substring(1);
        if (pattern.endsWith(r'$'))
          pattern = pattern.substring(0, pattern.length - 1);
        String newPattern;
        if (pattern == '/' || pattern.trim() == '') {
          newPattern = prefix.isEmpty
              ? r'^/?$'
              : '^' + prefix.replaceAll(RegExp(r'/$'), '') + r'/?$';
        } else {
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

  void useCors(
      {String origin = '*',
      String methods = 'GET, POST, PUT, DELETE, OPTIONS',
      String headers = 'Content-Type'}) {
    _corsOptions = {
      'Access-Control-Allow-Origin': origin,
      'Access-Control-Allow-Methods': methods,
      'Access-Control-Allow-Headers': headers,
    };
  }

  /// Inicia o servidor e processa as requisições.
  ///
  /// Example:
  /// ```dart
  /// app.listen(3000, () {
  ///   print('Server started on port 3000');
  /// });
  /// ```
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

      final List<Middleware> middlewares = List.from(_globalMiddlewares);
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
          final params = _extractRouteParams(
              (entry.value['paramNames'] as List).cast<String>(), match);
          req.params.addAll(params);
          final handlers = entry.value['handlers'];
          middlewares.addAll(handlers.whereType<Middleware>());
          middlewares.add((Request req, Response res, Next next) {
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
      if (req.timedOut || res.finished) return;
      if (index < middlewares.length) {
        try {
          final middleware = middlewares[index++];
          middleware(req, res, next);
        } catch (e) {
          _executeErrorMiddlewares(e, req, res);
        }
      }
    }

    next();
  }

  void _executeErrorMiddlewares(dynamic err, Request req, Response res) {
    int index = 0;
    void nextError() {
      if (index < _errorMiddlewares.length) {
        final errorMiddleware = _errorMiddlewares[index++];
        errorMiddleware(err, req, res, nextError);
      } else {
        if (!res.finished) {
          res
              .status(HttpStatus.internalServerError)
              .send({'error': err.toString()});
        }
      }
    }

    nextError();
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
