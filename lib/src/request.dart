part of 'darto_base.dart';

class Request {
  final HttpRequest _req;
  final bool _showLogger;
  final List<String?> _orderedParamValues;
  final Map<String, String> _params;

  Request(this._req, this._params, this._orderedParamValues, this._showLogger);

  bool _bodyRead = false;
  dynamic _cachedBody;
  Uint8List? _cachedBytes;
  Map<String, String> get param => _params;
  Map<String, dynamic>? file;
  int? timeout;
  bool timedOut = false;
  Uri get uri => _req.uri;
  String get method => _req.method;
  Map<String, String> get query => _req.uri.queryParameters;
  String get baseUrl => '/';
  DartoHeader get headers => DartoHeader(_req.headers);
  String get host => _req.headers.value(HttpHeaders.hostHeader) ?? '';
  String get hostname => host.contains(':') ? host.split(':')[0] : host;
  String get originalUrl => _req.uri.toString();
  String get path => _req.uri.path;
  String get ip => _req.connectionInfo?.remoteAddress.address ?? '';
  String get protocol => _req.requestedUri.scheme;
  Stream<List<int>> cast<T>() => _req.cast<List<int>>();
  List<String> get ips {
    final forwarded = _req.headers.value('x-forwarded-for');
    return forwarded != null && forwarded.isNotEmpty
        ? forwarded.split(',').map((ip) => ip.trim()).toList()
        : [ip];
  }

  final Map<String, dynamic> context = {};
  final Map<String, dynamic> session = {};

  void Function()? onResponseFinished;

  List<String?> params() {
    return _orderedParamValues;
  }

  // Método interno para ler os bytes do corpo da requisição e armazenar em cache.
  Future<Uint8List> _readBytes() async {
    if (_cachedBytes != null) return _cachedBytes!;
    final bytes =
        await _req.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
    _cachedBytes = Uint8List.fromList(bytes);
    return _cachedBytes!;
  }

  Future<dynamic> get body async {
    if (!_bodyRead) {
      final bytes = await _readBytes();
      // Decodifica os bytes para string utilizando UTF-8.
      final rawBody = utf8.decode(bytes);
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
      if (_req.connectionInfo != null && _showLogger) {
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
    if (_showLogger) {
      log.debug('Cookies: $cookieMap');
    }
    return cookieMap;
  }

  /// Retorna o corpo da requisição como bytes.
  Future<Uint8List> blob() async {
    return await _readBytes();
  }

  /// Retorna o corpo da requisição como ByteBuffer.
  Future<ByteBuffer> arrayBuffer() async {
    final bytes = await blob();
    return bytes.buffer;
  }

  /// Para requests do tipo "application/x-www-form-urlencoded"
  /// ou similar, retorna os dados do formulário.
  Future<dynamic> formData() async {
    final contentType = _req.headers.contentType?.mimeType ?? "";
    final text = await _bodyText();
    if (contentType == "application/x-www-form-urlencoded") {
      return Uri.splitQueryString(text);
    }
    // Para multipart/form-data, uma implementação mais completa é necessária.
    return text;
  }

  /// Transforma o corpo da requisição em uma String.
  Future<String> _bodyText() async {
    final b = await body;
    if (b is String) return b;
    if (b is Map || b is List) return jsonEncode(b);
    return b.toString();
  }

  Future<T> bodyParse<T>(T Function(dynamic body) parser) async {
    final b = await body;
    return parser(b);
  }
}

extension RequestExtensions on Request {
  Logger get log => Logger();
}
