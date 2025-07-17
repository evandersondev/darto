import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as p;

import 'darto_header.dart';
import 'darto_hooks.dart';
import 'layer.dart';
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
  final List<Layer> _layers = [];
  final Map<String, List<ParamMiddleware>> _paramCallbacks = {};
  final List<ErrorHandler> _errorMiddlewares = [];
  Map<String, List<String>> _corsOptions = {};

  String _basePath = '';

  Darto({bool? logger, bool? snakeCase, bool gzip = false})
      : _logger = logger ?? false,
        _snakeCase = snakeCase ?? false,
        _enableGzip = gzip;

  void set(String key, dynamic value) {
    _settings[key] = value;
  }

  void engine(String engine, String path) {
    _settings['views'] = path;
    _settings['view engine'] = engine;
  }

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
    if (pathOrBuilder is ErrorHandler && second == null) {
      _errorMiddlewares.add(pathOrBuilder);
    } else if (pathOrBuilder is Middleware && second == null) {
      _layers.add(Layer(
        handlers: [pathOrBuilder],
        paramCallbacks: _paramCallbacks,
      ));
    } else if (pathOrBuilder is Router && second == null) {
      _addRouterLayers('', pathOrBuilder);
    } else if (pathOrBuilder is String && second == null) {
      static(pathOrBuilder);
    } else if (pathOrBuilder is String && second is Middleware) {
      final paramNames = <String>[];
      String path = pathOrBuilder;
      if (_basePath.isNotEmpty) {
        String base = _basePath;
        if (!base.endsWith('/')) base = '$base/';
        if (path.startsWith('/')) path = path.substring(1);
        path = base + path;
      }
      String regexPattern =
          path.replaceAllMapped(RegExp(r'/:(\w+)\?'), (match) {
        paramNames.add(match.group(1)!);
        return '(?:/([^/]+))?';
      }).replaceAllMapped(RegExp(r'/:(\w+)'), (match) {
        paramNames.add(match.group(1)!);
        return '/([^/]+)';
      }).replaceAllMapped(RegExp(r'/\*'), (match) => '(?:/(.*))?');
      if (regexPattern.startsWith('/'))
        regexPattern = regexPattern.substring(1);
      final regex = regexPattern.isEmpty
          ? RegExp('^/?\$')
          : RegExp('^/?' + regexPattern + '/?\$');
      _layers.add(Layer(
        path: path,
        regex: regex,
        paramNames: paramNames,
        handlers: [second],
        paramCallbacks: _paramCallbacks,
      ));
    } else if (pathOrBuilder is String && second is Router) {
      _addRouterLayers(pathOrBuilder, second);
    } else if (pathOrBuilder is String && second is Function) {
      final prefix = pathOrBuilder;
      final builder = second;
      if (builder is RouterRouteBuilder) {
        final router = Router();
        builder(router);
        _addRouterLayers(prefix, router);
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
        _addRouterLayers('', router);
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

    timeoutMiddleware(Request req, Response res, NextFunction next) {
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

    _layers.insert(
        0,
        Layer(
          handlers: [timeoutMiddleware],
          paramCallbacks: _paramCallbacks,
        ));
  }

  void _addRoute(String method, String path, dynamic first,
      [dynamic second, dynamic third]) {
    if (_basePath.isNotEmpty) {
      String base = _basePath;
      if (!base.endsWith('/')) base = '$base/';
      if (path.startsWith('/')) path = path.substring(1);
      path = base + path;
    }
    if (path != "/" && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    final paramNames = <String>[];
    String regexPattern = path.replaceAllMapped(RegExp(r'/:(\w+)\?'), (match) {
      paramNames.add(match.group(1)!);
      return '(?:/([^/]+))?';
    }).replaceAllMapped(RegExp(r'/:(\w+)'), (match) {
      paramNames.add(match.group(1)!);
      return '/([^/]+)';
    }).replaceAllMapped(RegExp(r'/\*'), (match) => '(?:/(.*))?');
    if (regexPattern.startsWith('/')) regexPattern = regexPattern.substring(1);
    final regexPath = regexPattern.isEmpty
        ? RegExp('^/?\$')
        : RegExp('^/?' + regexPattern + '/?\$');

    final List<dynamic> handlers = [];
    if (first is Middleware || first is RouteHandler) handlers.add(first);
    if (second != null) handlers.add(second);
    if (third != null) handlers.add(third);
    if (handlers.isEmpty) {
      throw ArgumentError("A rota deve ter pelo menos um handler.");
    }

    _layers.add(Layer(
      path: path,
      regex: regexPath,
      paramNames: paramNames,
      method: method,
      handlers: handlers,
      paramCallbacks: _paramCallbacks,
    ));
  }

  void _addRouterLayers(String prefix, Router router) {
    if (_basePath.isNotEmpty) {
      String base = _basePath;
      if (!base.endsWith('/')) base = '$base/';
      if (prefix.startsWith('/')) prefix = prefix.substring(1);
      prefix = base + prefix;
    }
    // Normaliza o prefixo para regex
    String regexPrefix = prefix.isEmpty ? '' : prefix;
    if (regexPrefix.isNotEmpty && !regexPrefix.endsWith('/')) {
      regexPrefix += '/';
    }
    // Regex para corresponder ao prefixo e qualquer sub-caminho (incluindo vazio)
    final prefixRegex = regexPrefix.isEmpty
        ? RegExp('^/?(.*)\$')
        : RegExp('^/?' + RegExp.escape(regexPrefix) + '?(.*)\$');

    for (var layer in router._layers) {
      String? newPattern = layer.path;
      if (newPattern != null) {
        // Rotas ou middlewares com caminho específico
        if (newPattern.startsWith('/')) newPattern = newPattern.substring(1);
        newPattern = prefix.isEmpty
            ? '/$newPattern'
            : prefix.endsWith('/')
                ? '$prefix$newPattern'
                : '$prefix/$newPattern';
        if (newPattern != '/' && newPattern.endsWith('/')) {
          newPattern = newPattern.substring(0, newPattern.length - 1);
        }
        String regexPattern =
            newPattern.replaceAllMapped(RegExp(r'/:(\w+)\?'), (match) {
          return '(?:/([^/]+))?';
        }).replaceAllMapped(RegExp(r'/:(\w+)'), (match) {
          return '/([^/]+)';
        }).replaceAllMapped(RegExp(r'/\*'), (match) => '(?:/(.*))?');
        if (regexPattern.startsWith('/'))
          regexPattern = regexPattern.substring(1);
        final newRegex = regexPattern.isEmpty
            ? RegExp('^/?\$')
            : RegExp('^/?' + regexPattern + '/?\$');
        _layers.add(Layer(
          path: newPattern,
          regex: newRegex,
          paramNames: layer.paramNames,
          method: layer.method,
          handlers: layer.handlers,
          paramCallbacks: router._paramCallbacks,
        ));
      } else {
        // Middleware global do roteador, associar ao prefixo
        _layers.add(Layer(
          path: prefix.isEmpty ? '/' : prefix,
          regex: prefixRegex,
          paramNames: [],
          handlers: layer.handlers,
          paramCallbacks: router._paramCallbacks,
        ));
      }
    }
  }

  void param(String name, ParamMiddleware callback) {
    if (!_paramCallbacks.containsKey(name)) {
      _paramCallbacks[name] = [];
    }
    _paramCallbacks[name]!.add(callback);
  }

  void _addStaticRoute(String folder) {
    final regexPath = RegExp('^/$folder/(.*)');
    _layers.add(Layer(
      path: '/$folder',
      regex: regexPath,
      paramNames: [],
      method: 'GET',
      handlers: [
        (Request req, Response res, NextFunction next) async {
          final relativePath = req.uri.path.replaceFirst('/$folder/', '');
          final filePath =
              p.normalize(p.join(Directory.current.path, folder, relativePath));
          if (await File(filePath).exists()) {
            res.sendFile(filePath);
          } else {
            res.status(HttpStatus.notFound).send({'error': 'File not found'});
          }
        }
      ],
      paramCallbacks: _paramCallbacks,
    ));
  }

  void useCors({
    List<String> origin = const ['*'],
    List<String> methods = const ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    List<String> headers = const ['Content-Type'],
  }) {
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

      bool handled = false;
      final List<Middleware> middlewares = [];

      for (var layer in _layers) {
        if (layer.regex == null && layer.method == null) {
          middlewares.addAll(layer.handlers.whereType<Middleware>());
          continue;
        }
        final match = layer.regex?.firstMatch(path);
        if (match != null && (layer.method == null || layer.method == method)) {
          final orderedValues = _extractOrderedParams(layer.paramNames, match);
          final params = _extractRouteParams(layer.paramNames, match);
          req.param.addAll(params);
          req._orderedParamValues.clear();
          req._orderedParamValues.addAll(orderedValues);

          final routeParamCallbacks = layer.paramCallbacks;
          if (routeParamCallbacks.isNotEmpty) {
            middlewares
                .add((Request req, Response res, NextFunction next) async {
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

          middlewares.addAll(layer.handlers.whereType<Middleware>());
          if (layer.method != null) {
            middlewares
                .add((Request req, Response res, NextFunction next) async {
              try {
                await addHook.executePreHandler(req, res);
                final handler = layer.handlers.last;
                dynamic result;
                if (handler is RouteHandler) {
                  result = handler(req, res);
                } else if (handler is Middleware) {
                  result = await handler(req, res, next);
                }
                if (result is Future) result = await result;
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
      }

      _applyCors(req, res);
      if (req.method == 'OPTIONS') {
        res.status(204).end();
        continue;
      } else if (!handled) {
        addHook.executeOnNotFound(req, res);
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

    void nextError([dynamic error]) {
      if (index < _errorMiddlewares.length) {
        final errorMiddleware = _errorMiddlewares[index++];

        final captErr = error ?? err;
        final exception = captErr is Exception ? captErr : Exception(captErr);
        errorMiddleware(exception, req, res, nextError);
      }

      if (!res.finished) {
        res.error(error);
        addHook.executeOnError(error, req, res);
      }
    }

    nextError(err);
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

  void _applyCors(Request req, Response res) {
    if (_corsOptions.isEmpty) return;
    final origin = req.headers.get('origin');
    if (origin == null) return;

    final allowedOrigins = _corsOptions['Access-Control-Allow-Origin'] ?? [];
    final isOriginAllowed =
        allowedOrigins.contains('*') || allowedOrigins.contains(origin);

    if (!isOriginAllowed) return;

    for (var entry in _corsOptions.entries) {
      res.set(entry.key, entry.value.join(','));
    }

    res.set('Access-Control-Allow-Origin', origin);
  }
}

extension DartoExtensions on Darto {
  Logger get log => Logger();
}
