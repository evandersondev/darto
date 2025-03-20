import 'dart:convert';
import 'dart:io';

import 'package:darto/darto.dart';
import 'package:darto/src/darto_header.dart';
import 'package:darto/src/darto_logger.dart';

class Request {
  final HttpRequest _req;
  final Map<String, String> params;
  dynamic _cachedBody;
  bool _bodyRead = false;
  final Logger logger;

  // Informações de arquivo, se necessário.
  Map<String, dynamic>? file;

  // Valor do timeout (em milissegundos) definido pelo middleware.
  int? timeout;

  // Indica se a requisição já expirou.
  bool timedOut = false;

  /// Callback para ser executado quando a resposta é finalizada.
  void Function()? onResponseFinished;

  Request(this._req, this.params, this.logger);

  Uri get uri => _req.uri;
  String get method => _req.method;
  Map<String, String> get query => _req.uri.queryParameters;

  Future<String> get body async {
    if (!_bodyRead) {
      _cachedBody = await utf8.decoder.bind(_req).join();
      _bodyRead = true;
      if (_req.connectionInfo != null && logger.isActive(LogLevel.debug)) {
        DartoLogger.log(
          'Read request body from ${_req.connectionInfo!.remoteAddress.address}',
          LogLevel.debug,
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
    if (logger.isActive(LogLevel.debug)) {
      DartoLogger.log('Cookies: $cookieMap', LogLevel.debug);
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
