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

  // Propriedade para armazenar informações do arquivo carregado
  Map<String, dynamic>? file;

  Request(this._req, this.params, this.logger);

  /// Returns the original URL of the request.
  /// This is the same as [originalUrl].
  /// Example:  http://example.com/foo/bar?a=b
  Uri get uri => _req.uri;

  /// Returns the HTTP method of the request.
  /// This is the same as [method].
  /// Example: GET, POST, PUT, DELETE, etc.
  String get method => _req.method;
  Map<String, String> get query => _req.uri.queryParameters;

  /// Returns the parsed request body as a String.
  /// Note: This reads the entire body. For large bodies, consider a streaming approach.
  Future<String> get body async {
    if (!_bodyRead) {
      _cachedBody = await utf8.decoder.bind(_req).join();
      _bodyRead = true;
      if (_req.connectionInfo != null) {
        if (logger.isActive(LogLevel.debug)) {
          DartoLogger.log(
            'Read request body from ${_req.connectionInfo!.remoteAddress.address}',
            LogLevel.debug,
          );
        }
      }
    }
    return _cachedBody;
  }

  /// Returns all cookies sent by the client.
  /// Example: {'name': 'value'}
  Map<String, String> get cookies {
    final Map<String, String> cookieMap = {};
    for (var cookie in _req.cookies) {
      cookieMap[cookie.name] = cookie.value;
    }
    if (logger.isActive(LogLevel.debug)) {
      DartoLogger.log(
        'Cookies: $cookieMap',
        LogLevel.debug,
      );
    }
    return cookieMap;
  }

  /// Returns the full URL of the request.
  /// Example: '/'
  String get baseUrl => '/';

  /// Returns headers
  DartoHeader get headers => DartoHeader(_req.headers);

  /// Returns the full host header (e.g., "example.com:3000").
  String get host => _req.headers.value(HttpHeaders.hostHeader) ?? '';

  /// Returns the hostname without the port (e.g., "example.com").
  String get hostname {
    final h = host;
    if (h.contains(':')) {
      return h.split(':')[0];
    }
    return h;
  }

  /// Returns the original URL of the request.
  String get originalUrl => _req.uri.toString();

  /// Returns the path of the request URL.
  /// Example: '/foo/bar'
  String get path => _req.uri.path;

  /// Returns IP address of the client.
  /// If the 'x-forwarded-for' header is present, it will be used.
  /// Otherwise, the remote address of the request is used.
  /// Example: '127.0.0.1'
  String get ip {
    return _req.connectionInfo?.remoteAddress.address ?? '';
  }

  /// Returns a list of IP addresses of the client.
  /// If the 'x-forwarded-for' header is present, it will be used.
  /// Otherwise, the remote address of the request is used.
  /// Example: ['
  /// '127.0.0.1',
  /// '192.168.1.1',
  /// '10.0.0.1',
  /// ]
  List<String> get ips {
    final forwarded = _req.headers.value('x-forwarded-for');
    if (forwarded != null && forwarded.isNotEmpty) {
      return forwarded.split(',').map((ip) => ip.trim()).toList();
    }
    return [ip];
  }

  /// Returns the request protocol.
  /// Example: 'http'
  /// 'https'
  /// 'ws'
  /// 'wss'
  /// 'ftp'
  /// 'ftps'
  /// 'file'
  String get protocol {
    return _req.requestedUri.scheme;
  }

  Stream<List<int>> cast<T>() => _req.cast<List<int>>();
}
