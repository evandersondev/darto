part of 'darto_base.dart';

class Response {
  final HttpResponse _res;
  final bool _showLogger;
  final bool _snakeCase;
  final bool _enableGzip;

  Response(this._res, bool? showLogger, this._snakeCase,
      {bool enableGzip = false})
      : _enableGzip = enableGzip,
        _showLogger = showLogger ?? false;

  bool _finished = false;
  bool get finished => _finished;
  final Map<String, dynamic> locals = {};

  DartoHeader get headers => DartoHeader(_res.headers);

  Response status(int statusCode) {
    _res.statusCode = statusCode;
    if (_showLogger) {
      log.info('Response status set to $statusCode');
    }
    return this;
  }

  void set(String field, String value) {
    _res.headers.set(field, value);
    if (_showLogger) {
      log.info('Response header set: $field: $value');
    }
  }

  RenderLayout? _renderLayout;

  /// ```dart
  /// res.setRender((content) {
  ///   return res.html('''
  ///     <html>
  ///       <head>
  ///         <title>Meu titulo</title>
  ///       </head>
  ///       <body>
  ///         $content
  ///       </body>
  ///     </html>
  ///   ''');
  /// });
  /// ```
  void setRender(RenderLayout layout) {
    _renderLayout = layout;
    if (_showLogger) {
      log.info('Render layout configured.');
    }
  }

  void sendFile(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      _res.statusCode = HttpStatus.notFound;
      _res.write('File not found');
      await _res.close();
      _finished = true;
      if (_showLogger) {
        log.error('File not found: $filePath');
      }
      return;
    }

    final contentType = _getContentType(filePath);
    _res.headers.contentType = contentType;

    final enableGzip = Darto._settings['gzip'] == true;
    final acceptsGzip = _acceptsGzip();
    final compressibleTypes = [
      ContentType.text.mimeType,
      ContentType.html.mimeType,
      ContentType.json.mimeType,
      ContentType('application', 'javascript').mimeType,
      ContentType('text', 'css').mimeType,
    ];

    if (enableGzip &&
        acceptsGzip &&
        compressibleTypes.contains(contentType.mimeType)) {
      _res.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
      final gzipStream = file.openRead().transform(gzip.encoder);
      await gzipStream.pipe(_res);
    } else {
      await file.openRead().pipe(_res);
    }

    _finished = true;
    if (_showLogger) {
      log.info('File served: $filePath');
    }
  }

  ContentType _getContentType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'html':
        return ContentType.html;
      case 'css':
        return ContentType('text', 'css');
      case 'js':
        return ContentType('application', 'javascript');
      case 'json':
        return ContentType.json;
      case 'png':
        return ContentType('image', 'png');
      case 'jpg':
      case 'jpeg':
        return ContentType('image', 'jpeg');
      case 'gif':
        return ContentType('image', 'gif');
      case 'svg':
        return ContentType('image', 'svg+xml');
      case 'pdf':
        return ContentType('application', 'pdf');
      case 'xml':
        return ContentType('application', 'xml');
      case 'ico':
        return ContentType('image', 'x-icon');
      default:
        return ContentType.text;
    }
  }

  void send([dynamic data]) async {
    if (data == null) {
      end();
      _finished = true;
      return;
    }

    if (_res.headers.contentType != null) {
      if (data is String && data.trim().startsWith('<')) {
        _res.headers.contentType = ContentType.html;
      } else if (_res.headers.contentType!.value.contains('json')) {
        return json(data);
      } else {
        _res.headers.contentType = ContentType.text;
      }
    }

    final acceptsGzip = _acceptsGzip();

    if (_enableGzip &&
        acceptsGzip &&
        _res.headers.contentType?.mimeType == ContentType.text.mimeType) {
      _res.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
      final gzipSink = gzip.encoder.startChunkedConversion(_res);
      gzipSink.add(utf8.encode(data.toString()));
      gzipSink.close();
    } else {
      _res.write(data);
      await _res.close();
    }

    _finished = true;
    if (_showLogger) {
      log.info('Data sent: $data');
    }
  }

  /// Sends a JSON response.
  ///
  /// This method sets the Content-Type header to application/json and sends the provided data as JSON.
  /// Supported data types: Map and List.
  /// example:
  ///
  /// ```dart
  /// res.json({ 'message': 'Hello, World!' });
  /// or
  /// res.json([1, 2, 3]);
  void json(dynamic data) async {
    final jsonData = _toJson(data);
    _res.headers.contentType = ContentType.json;

    final acceptsGzip = _acceptsGzip();

    if (_enableGzip && acceptsGzip) {
      _res.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
      final gzipSink = gzip.encoder.startChunkedConversion(_res);
      gzipSink.add(utf8.encode(jsonData));
      gzipSink.close();
    } else {
      _res.write(jsonData);
      await _res.close();
    }

    _finished = true;
    if (_showLogger) {
      log.info('JSON data sent: $jsonData');
    }
  }

  void error([dynamic e]) {
    if (_finished) return;

    try {
      _res.statusCode = HttpStatus.internalServerError;
    } catch (err) {
      // Ignorar erro se os headers já foram enviados
    }

    final errorMessage = e != null ? e.toString() : 'Internal server error';
    final jsonResponse = {
      "status": HttpStatus.internalServerError,
      "error": "Internal server error",
      "message": errorMessage,
    };

    try {
      _res.headers.contentType = ContentType.json;
    } catch (err) {
      // Ignorar erro se os headers não puderem ser modificados
    }

    try {
      _res.add(utf8.encode(jsonEncode(jsonResponse)));
    } catch (err) {
      // Ignorar erro se o StreamSink já estiver vinculado a um stream
    }

    try {
      _res.close();
    } catch (err) {
      // Ignorar erro se a resposta já estiver sendo fechada ou fechada
    }

    _finished = true;

    if (_showLogger) {
      log.error('Error response sent: $errorMessage');
    }
  }

  /// The render method now receives two parameters:
  /// - [templateName]: the name of the template file (without extension)
  /// - [head]: a map with template variables, which will be processed using Mustache.
  ///
  /// After rendering, if a layout was configured with setRender, then the rendered content is
  /// passed to that layout function, wrapping it accordingly.
  Future<void> render(String templateName, Map<String, dynamic> head) async {
    final viewsDir = Darto._settings['views'] ?? 'views';
    final viewEngine = Darto._settings['view engine'] ?? 'mustache';
    final filePath = p.join(viewsDir, '$templateName.$viewEngine');
    final file = File(filePath);

    if (!await file.exists()) {
      _res.statusCode = HttpStatus.notFound;
      _res.write('Template not found: $filePath');
      await _res.close();
      _finished = true;
      return;
    }

    try {
      final templateContent = await file.readAsString();
      final template = Template(templateContent, name: templateName);
      final output = template.renderString(head);
      if (_renderLayout != null) {
        var result = _renderLayout!(output);
        if (result is Future<Response>) {
          await result;
        }
        _finished = true;
        return;
      }
      _res.headers.contentType = ContentType.html;
      _res.write(output);
      await _res.close();
      _finished = true;
    } catch (e) {
      error(e);
    }
  }

  // New method: res.text() - Returns plain text content.
  Future<Response> text(String data) async {
    _res.headers.contentType = ContentType.text;
    _res.write(data);
    await _res.close();
    _finished = true;
    if (_showLogger) {
      log.info('Text data sent: $data');
    }
    return this;
  }

  // New method: res.html() - Returns HTML content.
  Future<Response> html(String data) async {
    _res.headers.contentType = ContentType.html;
    _res.write(data);
    await _res.close();
    _finished = true;
    if (_showLogger) {
      log.info('HTML data sent: $data');
    }
    return this;
  }

  // New method: res.notFound() - Sends a 404 response.
  Future<Response> notFound() async {
    _res.statusCode = HttpStatus.notFound;
    _res.headers.contentType = ContentType.text;
    _res.write('404 - Not Found');
    await _res.close();
    _finished = true;
    if (_showLogger) {
      log.info('Sent 404 response');
    }
    return this;
  }

  // New method: res.body() - Sets status code, headers and sends the data accordingly.
  Future<Response> body(
      dynamic data, int status, Map<String, dynamic> headers) async {
    _res.statusCode = status;
    headers.forEach((key, value) {
      _res.headers.set(key, value.toString());
    });
    // Check content type and send data accordingly.
    if (data is Map<String, dynamic>) {
      // If data is a map, assume JSON.
      _res.headers.contentType = ContentType.json;
      _res.write(jsonEncode(data));
    } else {
      // Otherwise, send it as plain text.
      _res.headers.contentType = ContentType.text;
      _res.write(data.toString());
    }
    await _res.close();
    _finished = true;
    if (_showLogger) {
      log.info('Response body sent with status $status: $data');
    }
    return this;
  }

  String _toJson(dynamic data) {
    return jsonEncode(_toEncodable(data));
  }

  dynamic _toEncodable(dynamic item) {
    if (item == null) return null;
    if (item is List) {
      return item.map((element) => _toEncodable(element)).toList();
    } else if (item is Map) {
      return item.map((key, value) =>
          MapEntry(_snakeCase ? toSnakeCase(key) : key, _toEncodable(value)));
    } else if (item is DateTime) {
      return item.toIso8601String();
    } else if (item is double) {
      return item;
    } else if (_isCustomModel(item)) {
      return item.toString();
    }

    return item;
  }

  String toSnakeCase(String input) {
    if (input.isEmpty) return input;
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      if (i > 0 && input[i].toUpperCase() == input[i]) {
        buffer.write('_');
      }
      buffer.write(input[i].toLowerCase());
    }
    return buffer.toString();
  }

  bool _isCustomModel(dynamic item) {
    if (item == null) return false;
    try {
      return item is Object &&
          item is! Map &&
          item is! List &&
          item is! String &&
          item is! int &&
          item is! double &&
          item is! bool &&
          item is! DateTime;
    } catch (e) {
      return false;
    }
  }

  void end([dynamic data]) {
    if (data != null) {
      _res.write(data);
    }
    _res.close();
    _finished = true;
    if (_showLogger) {
      log.info('Response ended with data: $data');
    }
  }

  void download(String filePath, [dynamic filename, dynamic callback]) async {
    String? downloadName;
    Function? cb;
    if (filename is String) {
      downloadName = filename;
      if (callback is Function) {
        cb = callback;
      }
    } else if (filename is Function) {
      cb = filename;
      downloadName = null;
    }
    final file = File(filePath);
    try {
      if (!await file.exists()) {
        throw HttpException('File not found');
      }
      _res.headers.contentType = ContentType.binary;
      String dispositionFile = downloadName ?? p.basename(filePath);
      _res.headers.set(
          'Content-Disposition', 'attachment; filename="$dispositionFile"');
      await file.openRead().pipe(_res).catchError((err) {
        if (cb != null) cb(err);
      });
      if (cb != null) cb(null);
      if (_showLogger) {
        log.info('File downloaded: $filePath');
      }
      _finished = true;
    } catch (err) {
      if (cb != null) {
        cb(err);
      } else {
        _res.statusCode = HttpStatus.internalServerError;
        _res.write('Error while sending file: $err');
        _res.close();
        _finished = true;
        if (_showLogger) {
          log.error(
            'Error downloading file: $filePath - $err',
          );
        }
      }
    }
  }

  void removeHeader(String field) {
    try {
      _res.headers.removeAll(field); // remove todas as ocorrências do header
      if (_showLogger) {
        log.info('Header removed: $field');
      }
    } catch (e) {
      if (_showLogger) {
        log.error(
          'Error removing header $field: $e',
        );
      }
    }
  }

  void cookie(String name, String value, [Map<String, dynamic>? options]) {
    final opts = options ?? {};
    final buffer = StringBuffer();
    buffer.write('$name=$value');
    if (opts.containsKey('path')) {
      buffer.write('; Path=${opts['path']}');
    } else {
      buffer.write('; Path=/');
    }
    if (opts.containsKey('expires')) {
      final expires = opts['expires'];
      if (expires is DateTime) {
        buffer.write('; Expires=${HttpDate.format(expires)}');
      } else if (expires is String) {
        buffer.write('; Expires=$expires');
      }
    }
    if (opts.containsKey('maxAge')) {
      buffer.write('; Max-Age=${opts['maxAge']}');
    }
    if (opts['httpOnly'] == true) {
      buffer.write('; HttpOnly');
    }
    if (opts['secure'] == true) {
      buffer.write('; Secure');
    }
    if (opts.containsKey('sameSite')) {
      buffer.write('; SameSite=${opts['sameSite']}');
    }
    _res.headers.add(HttpHeaders.setCookieHeader, buffer.toString());
    if (_showLogger) {
      log.info('Set cookie: $name=$value');
    }
  }

  void clearCookie(String name, [Map<String, dynamic>? options]) {
    final opts = Map<String, dynamic>.from(options ?? {});
    opts['expires'] = DateTime.fromMillisecondsSinceEpoch(0);
    opts['maxAge'] = 0;
    cookie(name, '', opts);
    if (_showLogger) {
      log.info('Cleared cookie: $name');
    }
  }

  void redirect(String url) {
    _res.statusCode = HttpStatus.found;
    _res.headers.set(HttpHeaders.locationHeader, url);
    _res.close();
    _finished = true;
    if (_showLogger) {
      log.info('Redirected to: $url');
    }
  }

  Response type(String mimeType) {
    _res.headers.contentType = ContentType.parse(mimeType);
    if (_showLogger) {
      log.info('Content-Type set via type(): $mimeType');
    }
    return this;
  }

  Future<void> pipe(Stream<List<int>> stream) async {
    await stream.pipe(_res);
    _finished = true;
    if (_showLogger) {
      log.info('Stream piped to response');
    }
  }

  void setETag(String tag) {
    _res.headers.set('ETag', tag);
  }

  void setCacheControl(String value) {
    _res.headers.set('Cache-Control', value);
  }

  bool _acceptsGzip() {
    final enc = _res.headers.value('accept-encoding') ?? '';
    return enc.contains('gzip');
  }

  Future<Response> stream(
      FutureOr<void> Function(DartoStream stream) callback) async {
    if (_finished) throw StateError('Response already finished');
    _res.headers.set('Transfer-Encoding', 'chunked');
    final dartoStream = DartoStream(_res, _showLogger);
    try {
      await callback(dartoStream);
    } catch (e) {
      error(e);
    }
    _finished = true;
    return this;
  }

  Future<Response> streamText(
      FutureOr<void> Function(DartoStream stream) callback) async {
    if (_finished) throw StateError('Response already finished');
    _res.headers.contentType = ContentType.text;
    _res.headers.set('Transfer-Encoding', 'chunked');
    final dartoStream = DartoStream(_res, _showLogger);
    try {
      await callback(dartoStream);
    } catch (e) {
      error(e);
    }
    _finished = true;
    return this;
  }

  Future<Response> streamSSE(
      FutureOr<void> Function(DartoStream stream) callback) async {
    if (_finished) throw StateError('Response already finished');
    _res.headers.contentType = ContentType('text', 'event-stream');
    _res.headers.set('Cache-Control', 'no-cache');
    _res.headers.set('Connection', 'keep-alive');
    _res.headers.set('Transfer-Encoding', 'chunked');
    final dartoStream = DartoStream(_res, _showLogger);
    try {
      await callback(dartoStream);
    } catch (e) {
      error(e);
    }
    _finished = true;
    return this;
  }
}

extension ResponseExtension on Response {
  Logger get log => Logger();
}
