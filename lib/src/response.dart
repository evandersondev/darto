import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:darto/darto.dart';
import 'package:darto/src/darto_logger.dart';
import 'package:path/path.dart';

class Response {
  final HttpResponse res;
  final Logger logger;
  final bool snakeCase; // Adiciona a propriedade snakeCase
  final List<String> staticFolders; // Adiciona a propriedade staticFolder

  // Propriedade para indicar se a resposta já foi finalizada.
  bool _finished = false;
  bool get finished => _finished;

  Response(this.res, this.logger, this.snakeCase, this.staticFolders);

  /// Define status code da resposta.
  Response status(int statusCode) {
    res.statusCode = statusCode;
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Response status set to $statusCode', LogLevel.info);
    }
    return this;
  }

  /// Set the response header field to value.
  void set(String field, String value) {
    res.headers.set(field, value);
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Response header set: $field: $value', LogLevel.info);
    }
  }

  /// Return a static file.
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
    res.addStream(file.openRead()).then((_) {
      res.close();
      _finished = true;
      if (logger.isActive(LogLevel.info)) {
        DartoLogger.log('File served: $filePath', LogLevel.info);
      }
    }).catchError((error) {
      if (logger.isActive(LogLevel.error)) {
        DartoLogger.log(
            'Error serving file: $filePath - $error', LogLevel.error);
      }
    });
  }

  /// Determines the content type based on the file extension.
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

  /// Send data with content type text/plain.
  void send([dynamic data]) {
    if (data == null) {
      end();
      _finished = true;
      return;
    }
    res.headers.contentType = ContentType.text;
    res.write(_toJson(data));
    res.close();
    _finished = true;
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Data sent: $data', LogLevel.info);
    }
  }

  /// Send data with content type application/json.
  void json(dynamic data) {
    res.headers.contentType = ContentType.json;
    res.write(_toJson(data));
    res.close();
    _finished = true;
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('JSON data sent: $data', LogLevel.info);
    }
  }

  /// Método para tratar erros e enviar um JSON padrão.
  void error([dynamic e]) {
    res.statusCode = HttpStatus.internalServerError;
    final errorMessage = e != null ? e.toString() : 'Internal server error';
    final jsonResponse = {
      "status": HttpStatus.internalServerError,
      "error": "Internal server error",
      "message": errorMessage,
    };
    res.headers.contentType = ContentType.json;
    res.write(jsonEncode(jsonResponse));
    res.close();
    _finished = true;
    if (logger.isActive(LogLevel.error)) {
      DartoLogger.log('Error response sent: $errorMessage', LogLevel.error);
    }
  }

  /// Converts data to JSON, handling custom objects.
  String _toJson(dynamic data) {
    return jsonEncode(_toEncodable(data));
  }

  /// Converts custom objects to encodable Map.
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

  /// Converts a string from camelCase to snake_case.
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

  /// Converts an object to JSON using mirrors.
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

  /// Ends the response process.
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

  /// Sends a file as an attachment.
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

  /// Sets a cookie on the response.
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

  /// Clears a cookie by setting it with an expired date.
  void clearCookie(String name, [Map<String, dynamic>? options]) {
    final opts = Map<String, dynamic>.from(options ?? {});
    opts['expires'] = DateTime.fromMillisecondsSinceEpoch(0);
    opts['maxAge'] = 0;
    cookie(name, '', opts);
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Cleared cookie: $name', LogLevel.info);
    }
  }

  /// Redirects the request to a different URL.
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
