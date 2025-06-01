import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as p;

import 'darto_header.dart';
import 'darto_hooks.dart';
import 'logger.dart';
import 'types.dart';

part 'request.dart';
part 'response.dart';
part 'router.dart';

class Darto {
  final bool _logger;
  final bool _snakeCase;
  final List<String> _staticFolders = [];
  static final Map<String, dynamic> _settings = {};
  final bool _enableGzip;
  final Hooks addHook = Hooks();

  String _basePath = '';
  Map<String, String> _corsOptions = {};

  Darto({bool? logger, bool? snakeCase, bool gzip = false})
      : _logger = logger ?? false,
        _snakeCase = snakeCase ?? false,
        _enableGzip = gzip;

  final Map<String, List<MapEntry<RegExp, Map<String, dynamic>>>> _routes = {};
  final Map<String, List<ParamMiddleware>> _paramCallbacks = {};
  final List<Middleware> _globalMiddlewares = [];
  final List<Timeout> _errorMiddlewares = [];

  /// Sets a global configuration value.
  void set(String key, dynamic value) {
    _settings[key] = value;
  }

  void engine(String engine, String path) {
    _settings['views'] = path;
    _settings['view engine'] = engine;
  }

  /// Sets or gets the global base path for all routes.
  ///
  /// If called with a string, it sets the base path and returns the instance.
  /// If called without parameter, it returns the current base path.
  ///
  /// Example:
  /// ```dart
  /// void main() {
  ///   final app = Darto().basePath('/api');
  ///   // Or get via app.basePath();
  /// }
  /// ```
  dynamic basePath([String? path]) {
    if (path == null) {
      return _basePath;
    }
    _basePath = path.startsWith('/') ? path : '/$path';
    return this;
  }

  dynamic get(String path, [dynamic first, dynamic second, dynamic third]) {
    if (first == null) {
      return _settings[path];
    } else {
      _addRoute('GET', path, first, second, third);
    }
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

  void head(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('HEAD', path, first, second, third);
  }

  void trace(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('TRACE', path, first, second, third);
  }

  void options(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('OPTIONS', path, first, second, third);
  }

  void patch(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('PATCH', path, first, second, third);
  }

  void use(dynamic pathOrBuilder, [dynamic second]) {
    if (pathOrBuilder is Timeout && second == null) {
      _errorMiddlewares.add(pathOrBuilder);
    } else if (pathOrBuilder is Middleware) {
      _globalMiddlewares.add(pathOrBuilder);
    } else if (pathOrBuilder is Router && second == null) {
      _addRouterRoutes('', pathOrBuilder);
    } else if (pathOrBuilder is String && second == null) {
      static(pathOrBuilder);
    } else if (pathOrBuilder is String && second is Middleware) {
      _addRouteMiddleware(pathOrBuilder, second);
    } else if (pathOrBuilder is String && second is Router) {
      _addRouterRoutes(pathOrBuilder, second);
    } else if (pathOrBuilder is String && second is Function) {
      final prefix = pathOrBuilder;
      final builder = second;
      if (builder is RouterRouteBuilder) {
        final router = Router();
        builder(router);
        _addRouterRoutes(prefix, router);
      } else if (builder is DartoRouteBuilder) {
        builder(this);
      } else {
        throw ArgumentError('Invalid function type provided to use method');
      }
    } else if (pathOrBuilder is Function && second == null) {
      if (pathOrBuilder is DartoRouteBuilder) {
        pathOrBuilder(this);
      } else if (pathOrBuilder is RouterRouteBuilder) {
        final router = Router();
        pathOrBuilder(router);
        _addRouterRoutes('', router);
      } else {
        throw ArgumentError('Invalid function type provided to use method');
      }
    } else {
      throw ArgumentError('Invalid arguments for the use method');
    }
  }

  void static(String path) {
    _staticFolders.add(path);
    _addStaticRoute(path);
  }

  void timeout(int milliseconds) {
    set('timeout', milliseconds);

    timeoutMiddleware(Request req, Response res, Next next) {
      req.timeout = milliseconds;

      Timer timer = Timer(Duration(milliseconds: milliseconds), () {
        req.timedOut = true;
        if (!res.finished) {
          _executeErrorMiddlewares(Exception("Request timed out"), req, res);
        }
      });

      req.onResponseFinished = () {
        timer.cancel();
      };

      next();
    }

    _globalMiddlewares.insert(0, timeoutMiddleware);
  }

  void _addRoute(String method, String path, dynamic first,
      [dynamic second, dynamic third]) {
    // Aplica o basePath global.
    if (_basePath.isNotEmpty) {
      String base = _basePath;
      if (!base.endsWith('/')) {
        base = '$base/';
      }
      if (path.startsWith('/')) {
        path = path.substring(1);
      }
      path = base + path;
    }

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

    // Caso a rota seja a raiz, use ^/?$; senão, prefixe com '^/?'
    final regexPath = regexPattern.isEmpty
        ? RegExp('^/?\$')
        : RegExp('^/?' + regexPattern + '/?\$');

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
          MapEntry(regexPath, {
            'handlers': handlers,
            'paramNames': paramNames,
            'paramCallbacks': _paramCallbacks,
          }),
        );
  }

  void param(String name, ParamMiddleware callback) {
    if (!_paramCallbacks.containsKey(name)) {
      _paramCallbacks[name] = [];
    }
    _paramCallbacks[name]!.add(callback);
  }

  void _addRouteMiddleware(String path, Middleware middleware) {
    if (_basePath.isNotEmpty) {
      String base = _basePath;
      if (!base.endsWith('/')) {
        base = '$base/';
      }
      if (path.startsWith('/')) {
        path = path.substring(1);
      }
      path = base + path;
    }
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
            'paramNames': paramNames,
            'paramCallbacks': _paramCallbacks,
          }),
        );
  }

  void _addStaticRoute(String folder) {
    final regexPath = RegExp('^/$folder/(.*)');
    _routes.putIfAbsent('GET', () => []).add(
          MapEntry(
            regexPath,
            {
              'handlers': [
                (Request req, Response res, Next next) async {
                  final relativePath =
                      req.uri.path.replaceFirst('/$folder/', '');
                  final filePath = p.normalize(
                      p.join(Directory.current.path, folder, relativePath));
                  if (await File(filePath).exists()) {
                    res.sendFile(filePath);
                  } else {
                    res
                        .status(HttpStatus.notFound)
                        .send({'error': 'File not found'});
                  }
                }
              ],
              'paramNames': <String>[],
              'paramCallbacks': _paramCallbacks,
            },
          ),
        );
  }

  void _addRouterRoutes(String prefix, Router router) {
    if (_basePath.isNotEmpty) {
      String base = _basePath;
      if (!base.endsWith('/')) {
        base = '$base/';
      }
      if (prefix.startsWith('/')) {
        prefix = prefix.substring(1);
      }
      prefix = base + prefix;
    }
    router._routes.forEach((method, routeEntries) {
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
          newPattern = prefix.isEmpty
              ? '^/' + pattern + r'$'
              : '^' + normalizedPrefix + pattern + r'$';
        }
        final newRegex = RegExp(newPattern);
        var routeData = Map<String, dynamic>.from(entry.value);
        routeData['paramCallbacks'] = router._paramCallbacks;
        _routes.putIfAbsent(method, () => []).add(
              MapEntry(newRegex, routeData),
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

  Future<void> _executeSequentialMiddleware(
      List<Middleware> middlewares, Request req, Response res) async {
    int index = 0;
    Future<void> next([dynamic error]) async {
      if (index < middlewares.length) {
        var middleware = middlewares[index++];
        await middleware(req, res, next);
      }
    }

    await next();
  }

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

  Future<void> listen(int port, [void Function()? callback]) async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    if (_logger) {
      log.info('Server listening at ${server.address.address}:$port');
    }
    callback?.call();
    await for (HttpRequest request in server) {
      final method = request.method;
      final path = request.uri.path;
      if (_logger) {
        log.access(
          '[$method $path] - IP: ${request.connectionInfo?.remoteAddress.address}',
        );
      }

      final req = Request(request, {}, [], _logger);
      final res = Response(
        request.response,
        _logger,
        _snakeCase,
        enableGzip: _enableGzip,
      );
      addHook.executeOnRequest(req);

      final List<Middleware> middlewares = List.from(_globalMiddlewares);
      final routeEntries = _routes[method] ?? [];
      bool handled = false;

      // Processa middlewares de uso global (USE)
      for (var entry in _routes['USE'] ?? []) {
        final match = entry.key.firstMatch(path);
        if (match != null) {
          middlewares.addAll(entry.value['handlers'].cast<Middleware>());
        }
      }

      // Verifica se alguma rota corresponde
      for (var entry in routeEntries) {
        final match = entry.key.firstMatch(path);
        if (match != null) {
          final orderedValues = _extractOrderedParams(
              (entry.value['paramNames'] as List).cast<String>(), match);
          final params = _extractRouteParams(
              (entry.value['paramNames'] as List).cast<String>(), match);
          req.param.addAll(params);
          req._orderedParamValues.clear();
          req._orderedParamValues.addAll(orderedValues);

          final routeParamCallbacks = entry.value['paramCallbacks']
              as Map<String, List<ParamMiddleware>>?;
          if (routeParamCallbacks != null) {
            middlewares.add((Request req, Response res, Next next) async {
              List<Middleware> paramHandlers = [];
              req.param.forEach((key, value) {
                if (routeParamCallbacks.containsKey(key)) {
                  for (var callback in routeParamCallbacks[key]!) {
                    paramHandlers.add((req, res, next) {
                      callback(req, res, next, value);
                    });
                  }
                }
              });
              if (paramHandlers.isNotEmpty) {
                await _executeSequentialMiddleware(paramHandlers, req, res);
              }
              next();
            });
          }

          final handlers = entry.value['handlers'];
          middlewares.addAll(handlers.whereType<Middleware>());
          middlewares.add((Request req, Response res, Next next) async {
            try {
              await addHook.executePreHandler(req, res);
              final handler = handlers.last;
              dynamic result;
              if (handler is RouteHandler) {
                result = handler(req, res);
              } else if (handler is Middleware) {
                result = await handler(req, res, next);
              }
              if (result is Future) {
                result = await result;
              }
              if (result != null && !res.finished) {
                if (result is String) {
                  res.send(result);
                } else if (result is Map) {
                  res.json(result);
                } else {
                  res.send(result.toString());
                }
              }
            } catch (e) {
              _executeErrorMiddlewares(e, req, res);
            }
          });
          handled = true;
          break;
        }
      }

      // Se nenhuma rota foi encontrada, envia 404 imediatamente
      if (!handled) {
        _applyCors(res);
        addHook.executeOnNotFound(req, res);
        // if (!res.finished) {
        //   res
        //       .status(HttpStatus.notFound)
        //       .send({"404": "Route not found (Auto Redirect)"});
        // }
        continue;
      }
      _executeMiddlewares(req, res, middlewares);
      addHook.executeOnResponse(req, res);
    }
  }

  void _executeMiddlewares(
      Request req, Response res, List<Middleware> middlewares) {
    int index = 0;
    void next([dynamic error]) {
      if (error != null) {
        _executeErrorMiddlewares(error, req, res);
        return;
      }
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
          res.error(err);
          addHook.executeOnError(err, req, res);
        }
      }
    }

    nextError();
  }

  Map<String, String> _extractRouteParams(
      List<String> paramNames, Match match) {
    final params = <String, String>{};
    for (var i = 0; i < paramNames.length; i++) {
      final value = match.group(i + 1);
      if (value != null && value.isNotEmpty) {
        params[paramNames[i]] = value;
      }
    }
    return params;
  }

  List<String?> _extractOrderedParams(List<String> paramNames, Match match) {
    final orderedValues = <String?>[];
    for (var i = 0; i < paramNames.length; i++) {
      final value = match.group(i + 1);
      orderedValues.add(value);
    }
    return orderedValues;
  }

  void _applyCors(Response res) {
    _corsOptions.forEach((key, value) {
      res._res.headers.set(key, value);
    });
  }
}

extension DartoExtensions on Darto {
  Logger get log => Logger();
}
