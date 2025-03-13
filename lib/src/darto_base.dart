import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

typedef Handler = Future<void> Function(Request req, Response res);
typedef Middleware =
    Future<void> Function(Request req, Response res, Future<void> Function());

class Darto {
  final Map<String, List<MapEntry<RegExp, Map<String, dynamic>>>> _routes = {};
  final List<Middleware> _middlewares = [];
  String? _staticFolder;
  Map<String, String> _corsOptions = {}; // Configurações de CORS

  void get(String path, Handler handler) => _addRoute('GET', path, handler);
  void post(String path, Handler handler) => _addRoute('POST', path, handler);
  void put(String path, Handler handler) => _addRoute('PUT', path, handler);
  void delete(String path, Handler handler) =>
      _addRoute('DELETE', path, handler);

  void use(dynamic middlewareOrRouter) {
    if (middlewareOrRouter is Middleware) {
      _middlewares.add(middlewareOrRouter);
    } else if (middlewareOrRouter is Router) {
      middlewareOrRouter.routes.forEach((method, routes) {
        _routes.putIfAbsent(method, () => []).addAll(routes);
      });
    }
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

  void listen(int port, void Function()? callback) async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    callback?.call();

    print('🚀 Servidor rodando em http://localhost:$port');

    await for (HttpRequest request in server) {
      final method = request.method;
      final path = request.uri.path;

      // Verifica se está servindo arquivos estáticos antes das rotas
      if (_staticFolder != null && await _serveFile(request, path)) {
        continue;
      }

      final routeEntries = _routes[method] ?? [];
      bool handled = false;

      print('Request: $method $path'); // Log de depuração

      for (var entry in routeEntries) {
        print('Checking route: ${entry.key.pattern}'); // Log de depuração
        final match = entry.key.firstMatch(path);
        if (match != null) {
          print('Matched route: ${entry.key.pattern}'); // Log de depuração
          final params = extractRouteParams(
            entry.key,
            entry.value['paramNames'] ??
                [], // Garante que paramNames não seja nulo
            match,
          );
          print('Params: $params'); // Log de depuração

          final req = Request(request, params);
          final res = Response(request.response);

          if (entry.key.pattern.isNotEmpty) {
            int index = 0;
            Future<void> next() async {
              if (index < _middlewares.length) {
                final middleware = _middlewares[index++];
                await middleware(req, res, next);
              } else {
                await entry.value['handler'](req, res);
              }
            }

            // Aplica os cabeçalhos de CORS antes de chamar o handler
            _applyCors(res);

            await next();
          } else {
            _applyCors(Response(request.response)); // Aplica CORS no erro 404
            request.response
              ..statusCode = HttpStatus.notFound
              ..write(jsonEncode({'error': 'Rota não encontrada'}))
              ..close();
          }

          handled = true;
          break;
        }
      }

      if (!handled) {
        _applyCors(Response(request.response)); // Aplica CORS no erro 404
        request.response
          ..statusCode = HttpStatus.notFound
          ..write(jsonEncode({'error': 'Rota não encontrada'}))
          ..close();
      }
    }
  }

  void _addRoute(String method, String path, Handler handler) {
    final paramNames = <String>[];
    final isDynamic = path.contains(':');

    final regexPath = RegExp(
      '^' +
          path.replaceAllMapped(RegExp(r':(\w+)'), (match) {
            paramNames.add(match.group(1)!);
            return '([^/]+)';
          }) +
          r'$',
    );

    final routeEntry = MapEntry(regexPath, {
      'handler': handler,
      'paramNames': paramNames,
    });

    if (isDynamic) {
      _routes.putIfAbsent(method, () => []).add(routeEntry);
    } else {
      _routes.putIfAbsent(method, () => []).insert(0, routeEntry);
    }
  }

  /// 📌 **Função para Extrair Parâmetros da Rota**
  Map<String, String> extractRouteParams(
    RegExp pattern,
    List<String> paramNames,
    Match match,
  ) {
    final params = <String, String>{};
    for (var i = 0; i < paramNames.length; i++) {
      params[paramNames[i]] = match.group(i + 1) ?? '';
    }
    return params;
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

  /// 📌 **Aplica os cabeçalhos CORS na resposta**
  void _applyCors(Response res) {
    _corsOptions.forEach((key, value) {
      res._res.headers.set(key, value);
    });
  }

  /// 📌 **Função para Servir Arquivos Estáticos**
  Future<bool> _serveFile(HttpRequest request, String path) async {
    final filePath = p.join('$_staticFolder$path');
    final file = File(filePath);

    if (await file.exists()) {
      request.response.headers.contentType = _getContentType(filePath);
      await file.openRead().pipe(request.response);
      return true;
    }

    return false;
  }
}

class Router {
  final Map<String, List<MapEntry<RegExp, Map<String, dynamic>>>> routes = {};

  void get(String path, Handler handler) => _addRoute('GET', path, handler);
  void post(String path, Handler handler) => _addRoute('POST', path, handler);
  void put(String path, Handler handler) => _addRoute('PUT', path, handler);
  void delete(String path, Handler handler) =>
      _addRoute('DELETE', path, handler);

  void _addRoute(String method, String path, Handler handler) {
    final paramNames = <String>[];
    final regexPath = RegExp(
      '^' +
          path.replaceAllMapped(RegExp(r':(\w+)'), (match) {
            paramNames.add(match.group(1)!);
            return '([^/]+)';
          }) +
          r'$',
    );

    routes
        .putIfAbsent(method, () => [])
        .add(
          MapEntry(regexPath, {'handler': handler, 'paramNames': paramNames}),
        );
  }
}

class Request {
  final HttpRequest _req;
  final Map<String, String> params;

  Request(this._req, this.params);

  Uri get uri => _req.uri;
  String get method => _req.method;
  Map<String, String> get query => _req.uri.queryParameters;
}

class Response {
  final HttpResponse _res;

  Response(this._res);

  void send(dynamic data) {
    _res.headers.contentType = ContentType.json;
    _res.write(jsonEncode(data));
    _res.close();
  }
}
