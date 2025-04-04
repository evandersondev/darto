import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart';

import 'package:darto/darto.dart';
import 'package:darto/src/darto_logger.dart';

class Response {
  final HttpResponse res;
  final Logger logger;
  final bool snakeCase;
  final List<String> staticFolders;

  bool _finished = false;
  bool get finished => _finished;

  Response(this.res, this.logger, this.snakeCase, this.staticFolders);

  Response status(int statusCode) {
    res.statusCode = statusCode;
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Response status set to $statusCode', LogLevel.info);
    }
    return this;
  }

  void set(String field, String value) {
    res.headers.set(field, value);
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Response header set: $field: $value', LogLevel.info);
    }
  }

  void sendFile(String filePath) {
    final file = File(filePath);

    if (!file.existsSync()) {
      res.statusCode = HttpStatus.notFound;
      res.write('File not found');
      res.close();
      _finished = true;
      if (logger.isActive(LogLevel.error)) {
        DartoLogger.log('File not found: $filePath', LogLevel.error);
      }
      return;
    }

    res.headers.contentType = _getContentType(filePath);
    file.openRead().pipe(res).whenComplete(() {
      _finished = true;
      if (logger.isActive(LogLevel.info)) {
        DartoLogger.log('File served: $filePath', LogLevel.info);
      }
    });
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

  void send([dynamic data]) {
    if (data == null) {
      end();
      _finished = true;
      return;
    }

    if (res.headers.contentType == null) {
      if (data is String && data.trim().startsWith('<')) {
        res.headers.contentType = ContentType.html;
      } else {
        res.headers.contentType = ContentType.text;
      }
    }

    res.write(data);
    res.close();
    _finished = true;
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Data sent: $data', LogLevel.info);
    }
  }

  void json(dynamic data) {
    res.headers.contentType = ContentType.json;
    res.write(_toJson(data));
    res.close();
    _finished = true;
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('JSON data sent: $data', LogLevel.info);
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

    if (logger.isActive(LogLevel.error)) {
      DartoLogger.log('Error response sent: $errorMessage', LogLevel.error);
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
      return _mirrorToJson(item);
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
      final instanceMirror = reflect(item);
      return instanceMirror.type.isSubclassOf(reflectClass(Object)) &&
          !instanceMirror.type.isSubtypeOf(reflectClass(Map)) &&
          !instanceMirror.type.isSubtypeOf(reflectClass(String)) &&
          !instanceMirror.type.isSubtypeOf(reflectClass(int)) &&
          !instanceMirror.type.isSubtypeOf(reflectClass(bool)) &&
          !instanceMirror.type.isSubtypeOf(reflectClass(DateTime)) &&
          !instanceMirror.type.isSubtypeOf(reflectClass(List));
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> _mirrorToJson(dynamic instance) {
    var instanceMirror = reflect(instance);
    var data = <String, dynamic>{};
    instanceMirror.type.declarations.forEach((symbol, declaration) {
      if (declaration is VariableMirror && !declaration.isStatic) {
        var fieldName = MirrorSystem.getName(symbol);
        var fieldValue =
            _toEncodable(instanceMirror.getField(symbol).reflectee);
        data[snakeCase ? toSnakeCase(fieldName) : fieldName] = fieldValue;
      }
    });
    return data;
  }

  void end([dynamic data]) {
    if (data != null) {
      res.write(data);
    }
    res.close();
    _finished = true;
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Response ended with data: $data', LogLevel.info);
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
      if (logger.isActive(LogLevel.info)) {
        DartoLogger.log('File downloaded: $filePath', LogLevel.info);
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
        if (logger.isActive(LogLevel.error)) {
          DartoLogger.log(
              'Error downloading file: $filePath - $err', LogLevel.error);
        }
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
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Set cookie: $name=$value', LogLevel.info);
    }
  }

  void clearCookie(String name, [Map<String, dynamic>? options]) {
    final opts = Map<String, dynamic>.from(options ?? {});
    opts['expires'] = DateTime.fromMillisecondsSinceEpoch(0);
    opts['maxAge'] = 0;
    cookie(name, '', opts);
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Cleared cookie: $name', LogLevel.info);
    }
  }

  void redirect(String url) {
    res.statusCode = HttpStatus.found;
    res.headers.set(HttpHeaders.locationHeader, url);
    res.close();
    _finished = true;
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Redirected to: $url', LogLevel.info);
    }
  }
}
