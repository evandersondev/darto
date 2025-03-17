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

  Uri get uri => _req.uri;
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

  /// Returns cookies as a Map with cookie name as key and value as value.
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

  /// In Express, baseUrl is the URL path on which a router was mounted.
  /// For simplicity, we assume the root path.
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

  /// Returns the path portion of the request URL.
  String get path => _req.uri.path;

  /// Returns the client's IP address.
  String get ip {
    return _req.connectionInfo?.remoteAddress.address ?? '';
  }

  /// Returns a list of IP addresses, using 'x-forwarded-for' header if available.
  List<String> get ips {
    final forwarded = _req.headers.value('x-forwarded-for');
    if (forwarded != null && forwarded.isNotEmpty) {
      return forwarded.split(',').map((ip) => ip.trim()).toList();
    }
    return [ip];
  }

  /// Returns the protocol used, for example 'http' or 'https'.
  String get protocol {
    // requestedUri.scheme is expected to provide the proper scheme.
    return _req.requestedUri.scheme;
  }

  /// Permite fazer cast para List<int>
  Stream<List<int>> cast<T>() => _req.cast<List<int>>();
}
