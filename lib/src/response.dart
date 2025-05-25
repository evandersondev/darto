import 'dart:convert';
import 'dart:io';

import 'package:darto/darto.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart';

class Response {
  final HttpResponse res;
  final bool _showLogger;
  final bool snakeCase;
  final List<String> staticFolders;
  final bool _enableGzip;

  bool _finished = false;
  bool get finished => _finished;
  final Map<String, dynamic> locals = {};

  Response(this.res, bool? showLogger, this.snakeCase, this.staticFolders,
      {bool enableGzip = false})
      : _enableGzip = enableGzip,
        _showLogger = showLogger ?? false;

  Response status(int statusCode) {
    res.statusCode = statusCode;
    if (_showLogger) {
      log.info('Response status set to $statusCode');
    }
    return this;
  }

  void set(String field, String value) {
    res.headers.set(field, value);
    if (_showLogger) {
      log.info('Response header set: $field: $value');
    }
  }

  void sendFile(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      res.statusCode = HttpStatus.notFound;
      res.write('File not found');
      await res.close();
      _finished = true;
      if (_showLogger) {
        log.error('File not found: $filePath');
      }
      return;
    }

    final contentType = _getContentType(filePath);
    res.headers.contentType = contentType;

    final enableGzip = Darto.settings['gzip'] == true;
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
      res.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
      final gzipStream = file.openRead().transform(gzip.encoder);
      await gzipStream.pipe(res);
    } else {
      await file.openRead().pipe(res);
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

    if (res.headers.contentType != null) {
      if (data is String && data.trim().startsWith('<')) {
        res.headers.contentType = ContentType.html;
      } else if (res.headers.contentType!.value.contains('json')) {
        return json(data);
      } else {
        res.headers.contentType = ContentType.text;
      }
    }

    final acceptsGzip = _acceptsGzip();

    if (_enableGzip &&
        acceptsGzip &&
        res.headers.contentType?.mimeType == ContentType.text.mimeType) {
      res.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
      final gzipSink = gzip.encoder.startChunkedConversion(res);
      gzipSink.add(utf8.encode(data.toString()));
      gzipSink.close();
    } else {
      res.write(data);
      await res.close();
    }

    _finished = true;
    if (_showLogger) {
      log.info('Data sent: $data');
    }
  }

  void json(dynamic data) async {
    final jsonData = _toJson(data);
    res.headers.contentType = ContentType.json;

    final acceptsGzip = _acceptsGzip();

    if (_enableGzip && acceptsGzip) {
      res.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
      final gzipSink = gzip.encoder.startChunkedConversion(res);
      gzipSink.add(utf8.encode(jsonData));
      gzipSink.close();
    } else {
      res.write(jsonData);
      await res.close();
    }

    _finished = true;
    if (_showLogger) {
      log.info('JSON data sent: $jsonData');
    }
  }

  void error([dynamic e]) {
    if (_finished) return;

    try {
      res.statusCode = HttpStatus.internalServerError;
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
      res.headers.contentType = ContentType.json;
    } catch (err) {
      // Ignorar erro se os headers não puderem ser modificados
    }

    try {
      res.add(utf8.encode(jsonEncode(jsonResponse)));
    } catch (err) {
      // Ignorar erro se o StreamSink já estiver vinculado a um stream
    }

    try {
      res.close();
    } catch (err) {
      // Ignorar erro se a resposta já estiver sendo fechada ou fechada
    }

    _finished = true;

    if (_showLogger) {
      log.error('Error response sent: $errorMessage');
    }
  }

  Future<void> render(String viewName, [Map<String, dynamic>? data]) async {
    final viewsDir = Darto.settings['views'] ?? 'views';
    final viewEngine = Darto.settings['view engine'] ?? 'mustache';

    final filePath = join(viewsDir, '$viewName.$viewEngine');
    final file = File(filePath);
    if (!await file.exists()) {
      res.statusCode = HttpStatus.notFound;
      res.write('Template not found: $filePath');
      await res.close();
      _finished = true;
      return;
    }

    try {
      final templateContent = await file.readAsString();
      final template = Template(templateContent, name: viewName);
      final output = template.renderString(data ?? {});
      res.headers.contentType = ContentType.html;
      res.write(output);
      await res.close();
      _finished = true;
    } catch (e) {
      error(e);
    }
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
          MapEntry(snakeCase ? toSnakeCase(key) : key, _toEncodable(value)));
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
      res.write(data);
    }
    res.close();
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
      res.headers.contentType = ContentType.binary;
      String dispositionFile = downloadName ?? basename(filePath);
      res.headers.set(
          'Content-Disposition', 'attachment; filename="$dispositionFile"');
      await file.openRead().pipe(res).catchError((err) {
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
        res.statusCode = HttpStatus.internalServerError;
        res.write('Error while sending file: $err');
        res.close();
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
      res.headers.removeAll(field); // remove todas as ocorrências do header
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
    res.headers.add(HttpHeaders.setCookieHeader, buffer.toString());
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
    res.statusCode = HttpStatus.found;
    res.headers.set(HttpHeaders.locationHeader, url);
    res.close();
    _finished = true;
    if (_showLogger) {
      log.info('Redirected to: $url');
    }
  }

  Response type(String mimeType) {
    res.headers.contentType = ContentType.parse(mimeType);
    if (_showLogger) {
      log.info('Content-Type set via type(): $mimeType');
    }
    return this;
  }

  Future<void> pipe(Stream<List<int>> stream) async {
    await stream.pipe(res);
    _finished = true;
    if (_showLogger) {
      log.info('Stream piped to response');
    }
  }

  void setETag(String tag) {
    res.headers.set('ETag', tag);
  }

  void setCacheControl(String value) {
    res.headers.set('Cache-Control', value);
  }

  bool _acceptsGzip() {
    final enc = res.headers.value('accept-encoding') ?? '';
    return enc.contains('gzip');
  }
}

extension ResponseExtension on Response {
  Logger get log => Logger();
}
