import 'dart:async';
import 'dart:io';

import 'package:darto/darto.dart';
import 'package:darto/src/darto_hooks.dart';
import 'package:path/path.dart' as p;

class Darto {
  final bool _logger;
  final bool _snakeCase;
  final List<String> _staticFolders = [];
  static final Map<String, dynamic> settings = {};
  final bool _enableGzip;
  final Hooks addHook = Hooks();

  Darto({bool? logger, bool? snakeCase, bool gzip = false})
      : _logger = logger ?? false,
        _snakeCase = snakeCase ?? false,
        _enableGzip = gzip;

  final Map<String, List<MapEntry<RegExp, Map<String, dynamic>>>> _routes = {};
  final List<Middleware> _globalMiddlewares = [];
  Map<String, List<String>> _corsOptions = {};
  final Map<String, List<ParamMiddleware>> paramCallbacks = {};

  // List of error middlewares (including timeout middleware)
  final List<Timeout> _errorMiddlewares = [];

  /// Sets a global configuration value.
  void set(String key, dynamic value) {
    settings[key] = value;
  }

  void engine(String engine, String path) {
    settings['views'] = path;
    settings['view engine'] = engine;
  }

  /// GET method with dual behavior:
  /// - If called with only a string, it returns a configuration value.
  /// - If called with handlers, it registers a GET route.
  ///
  /// Example:
  /// ```dart
  /// app.get('/hello', (Request req, Response res) {
  ///   res.send('Hello, World!');
  /// });
  /// ```
  dynamic get(String path, [dynamic first, dynamic second, dynamic third]) {
    if (first == null) {
      return settings[path];
    } else {
      _addRoute('GET', path, first, second, third);
    }
  }

  /// Registers a POST route.
  void post(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('POST', path, first, second, third);
  }

  /// Registers a PUT route.
  void put(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('PUT', path, first, second, third);
  }

  /// Registers a DELETE route.
  void delete(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('DELETE', path, first, second, third);
  }

  /// Registers a HEAD route.
  void head(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('HEAD', path, first, second, third);
  }

  /// Registers a TRACE route.
  void trace(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('TRACE', path, first, second, third);
  }

  /// Registers an OPTIONS route.
  void options(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('OPTIONS', path, first, second, third);
  }

  /// Registers a PATCH route.
  void patch(String path, dynamic first, [dynamic second, dynamic third]) {
    _addRoute('PATCH', path, first, second, third);
  }

  /// Registers middlewares, sub-routers, or static folders.
  ///
  /// If the first parameter is a function compatible with [Timeout],
  /// it is registered as an error-handling middleware (e.g., timeout).
  ///
  /// Additionally, if a single String parameter is provided, it is treated
  /// as a static folder.
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

  /// Defines a static folder.
  void static(String path) {
    _staticFolders.add(path);
    _addStaticRoute(path);
  }

  /// Defines a global timeout for requests in milliseconds.
  ///
  /// Example:
  /// ```dart
  /// app.timeout(5000);
  /// ```
  void timeout(int milliseconds) {
    set('timeout', milliseconds);

    // Middleware that sets the timeout value in req.timeout and triggers an error if exceeded.
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
          MapEntry(regexPath, {
            'handlers': handlers,
            'paramNames': paramNames,
            'paramCallbacks': paramCallbacks,
          }),
        );
  }

  void param(String name, ParamMiddleware callback) {
    if (!paramCallbacks.containsKey(name)) {
      paramCallbacks[name] = [];
    }
    paramCallbacks[name]!.add(callback);
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
            'paramNames': paramNames,
            'paramCallbacks': paramCallbacks,
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
              'paramCallbacks': paramCallbacks,
            },
          ),
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
          newPattern = prefix.isEmpty
              ? '^/' + pattern + r'$'
              : '^' + normalizedPrefix + pattern + r'$';
        }
        final newRegex = RegExp(newPattern);
        var routeData = Map<String, dynamic>.from(entry.value);
        // Attach paramCallbacks from the Router to the route data.
        routeData['paramCallbacks'] = router.paramCallbacks;
        _routes.putIfAbsent(method, () => []).add(
              MapEntry(newRegex, routeData),
            );
      }
    });
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

  /// Starts the server and processes incoming requests.
  ///
  /// Example:
  /// ```dart
  /// app.listen(3000, () {
  ///   print('Server started on port 3000');
  /// });
  /// ```
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

      final req = Request(request, {}, _logger);
      final res = Response(
        request.response,
        _logger,
        _snakeCase,
        _staticFolders,
        enableGzip: _enableGzip,
      );

      addHook.executeOnRequest(req);

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

          // If there are param callbacks registered, add a middleware to execute them.
          final routeParamCallbacks = entry.value['paramCallbacks']
              as Map<String, List<ParamMiddleware>>?;
          if (routeParamCallbacks != null) {
            middlewares.add((Request req, Response res, Next next) async {
              List<Middleware> paramHandlers = [];
              req.params.forEach((key, value) {
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

          // Wrap the final handler for asynchronous execution.
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

      // attach cors headers
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

  // Executes error middlewares and calls res.error() for a default JSON response.
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
      params[paramNames[i]] = match.group(i + 1) ?? '';
    }
    return params;
  }

  void _applyCors(Request req, Response res) {
    // CORS not configured, do nothing
    if (_corsOptions.isEmpty) return;

    // Not a cross-origin request, no CORS headers needed
    final origin = req.headers.get('origin');
    if (origin == null) return;

    final allowedOrigins = _corsOptions['Access-Control-Allow-Origin'] ?? [];

    final isOriginAllowed =
        allowedOrigins.contains('*') || allowedOrigins.contains(origin);

    // If the origin is not allowed, do NOT set CORS headers.
    // The browser will then block the request.
    if (!isOriginAllowed) return;

    // Set CORS default headers
    for (var entry in _corsOptions.entries) {
      res.set(entry.key, entry.value.join(','));
    }

    // override allow origin header to echo origin
    // This correctly handles the '*' case as per CORS spec.
    res.set('Access-Control-Allow-Origin', origin);
  }
}

extension DartoExtensions on Darto {
  Logger get log => Logger();
}
