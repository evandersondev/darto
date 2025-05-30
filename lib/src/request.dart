import 'dart:convert';
import 'dart:io';

import 'package:darto/darto.dart';
import 'package:darto/src/darto_header.dart';

class Request {
  final HttpRequest _req;
  final Map<String, String> params;
  dynamic _cachedBody;
  bool _bodyRead = false;
  final bool showLogger;

  // Informações de arquivo, se necessário.
  Map<String, dynamic>? file;

  // Valor do timeout (em milissegundos) definido pelo middleware.
  int? timeout;

  // Indica se a requisição já expirou.
  bool timedOut = false;

  // Context shared for all requests.
  final Map<String, dynamic> context = {};

  final Map<String, dynamic> session = {};

  /// Callback para ser executado quando a resposta é finalizada.
  void Function()? onResponseFinished;

  Request(this._req, this.params, this.showLogger);

  Uri get uri => _req.uri;
  String get method => _req.method;
  Map<String, String> get query => _req.uri.queryParameters;

  Future<dynamic> get body async {
    if (!_bodyRead) {
      String rawBody = await utf8.decoder.bind(_req).join();
      _bodyRead = true;

      final contentType = _req.headers.contentType?.mimeType;
      if (contentType != null) {
        if (contentType == 'application/json') {
          _cachedBody = jsonDecode(rawBody);
        } else if (contentType == 'application/x-www-form-urlencoded') {
          _cachedBody = Uri.splitQueryString(rawBody);
        } else if (contentType == 'text/plain') {
          _cachedBody = rawBody;
        } else {
          _cachedBody = rawBody;
        }
      } else {
        _cachedBody = rawBody;
      }

      if (_req.connectionInfo != null && showLogger) {
        log.debug(
          'Read request body from ${_req.connectionInfo!.remoteAddress.address}',
        );
      }
    }
    return _cachedBody;
  }

  Map<String, String> get cookies {
    final cookieMap = <String, String>{};
    for (var cookie in _req.cookies) {
      cookieMap[cookie.name] = cookie.value;
    }
    if (showLogger) {
      log.debug('Cookies: $cookieMap');
    }
    return cookieMap;
  }

  String get baseUrl => '/';
  DartoHeader get headers => DartoHeader(_req.headers);
  String get host => _req.headers.value(HttpHeaders.hostHeader) ?? '';
  String get hostname => host.contains(':') ? host.split(':')[0] : host;
  String get originalUrl => _req.uri.toString();
  String get path => _req.uri.path;
  String get ip => _req.connectionInfo?.remoteAddress.address ?? '';
  List<String> get ips {
    final forwarded = _req.headers.value('x-forwarded-for');
    return forwarded != null && forwarded.isNotEmpty
        ? forwarded.split(',').map((ip) => ip.trim()).toList()
        : [ip];
  }

  String get protocol => _req.requestedUri.scheme;
  Stream<List<int>> cast<T>() => _req.cast<List<int>>();
}

extension RequestExtensions on Request {
  Logger get log => Logger();
}
