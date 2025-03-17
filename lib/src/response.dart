import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:darto/src/darto_logger.dart';
import 'package:darto/src/logger.dart'; // Importa a classe de log
import 'package:path/path.dart' as p;

class Response {
  final HttpResponse res;
  final Logger logger;
  final bool snakeCase; // Adiciona a propriedade snakeCase
  final String? staticFolder; // Adiciona a propriedade staticFolder

  Response(this.res, this.logger, this.snakeCase, [this.staticFolder]);

  /// Define o status da resposta.
  /// Aceita [statusCode] do tipo int ou um [HttpStatus] da biblioteca dart:io.
  Response status(int statusCode) {
    res.statusCode = statusCode;
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Response status set to $statusCode', LogLevel.info);
    }
    return this;
  }

  /// Set the response header field to value.
  /// Multiple calls to this method will append values to the header field.
  /// Example:
  /// res.set('Content-Type', 'text/plain');
  void set(String field, String value) {
    res.headers.set(field, value);
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Response header set: $field: $value', LogLevel.info);
    }
  }

  /// Sends a file as the response.
  void render(String filePath) {
    print('Rendering file: $filePath');
    final file =
        File(staticFolder != null ? p.join(staticFolder!, filePath) : filePath);

    if (!file.existsSync()) {
      res.statusCode = HttpStatus.notFound;
      res.write('File not found');
      res.close();
      if (logger.isActive(LogLevel.error)) {
        DartoLogger.log('File not found: $filePath', LogLevel.error);
      }
      return;
    }

    res.headers.contentType = _getContentType(filePath);
    res.addStream(file.openRead()).then((_) {
      res.close();
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
    final extension = filePath.split('.').last;
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
      default:
        return ContentType.text;
    }
  }

  /// Envia os dados como resposta e encerra a resposta.
  void send(dynamic data) {
    res.headers.contentType = ContentType.text;
    res.write(jsonEncode(data));
    res.close();
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Data sent: $data', LogLevel.info);
    }
  }

  /// Envia os dados como resposta e encerra a resposta.
  void json(dynamic data) {
    res.headers.contentType = ContentType.json;
    res.write(_toJson(data));
    res.close();
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('JSON data sent: $data', LogLevel.info);
    }
  }

  /// Converts data to JSON, handling custom objects.
  String _toJson(dynamic data) {
    return jsonEncode(_toEncodable(data));
  }

  /// Converts custom objects to encodable Map.
  dynamic _toEncodable(dynamic item) {
    if (item is List) {
      return item.map((element) => _toEncodable(element)).toList();
    } else if (item is Map) {
      return item.map((key, value) =>
          MapEntry(snakeCase ? toSnakeCase(key) : key, _toEncodable(value)));
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

  /// Checks if the object is a custom model using reflection.
  bool _isCustomModel(dynamic item) {
    try {
      final instanceMirror = reflect(item);
      return instanceMirror.type.isSubclassOf(reflectClass(Object)) &&
          !instanceMirror.type.isSubtypeOf(reflectClass(Map)) &&
          !instanceMirror.type.isSubtypeOf(reflectClass(String)) &&
          !instanceMirror.type.isSubtypeOf(reflectClass(int)) &&
          !instanceMirror.type.isSubtypeOf(reflectClass(bool)) &&
          !instanceMirror.type.isSubtypeOf(reflectClass(List));
    } catch (e) {
      return false;
    }
  }

  /// Converts an object to JSON using mirrors.
  Map<String, dynamic> _mirrorToJson(dynamic instance) {
    var instanceMirror = reflect(instance);
    var data = <String, dynamic>{};

    // Iterates over all fields of the class
    instanceMirror.type.declarations.forEach((symbol, declaration) {
      if (declaration is VariableMirror && !declaration.isStatic) {
        var fieldName = MirrorSystem.getName(symbol);
        var fieldValue = instanceMirror.getField(symbol).reflectee;
        data[snakeCase ? toSnakeCase(fieldName) : fieldName] = fieldValue;
      }
    });

    return data;
  }

  /// Encerra a resposta.
  /// Se [data] for passado, ele será escrito antes de fechar a conexão.
  void end([dynamic data]) {
    if (data != null) {
      res.write(data);
    }
    res.close();
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Response ended with data: $data', LogLevel.info);
    }
  }

  void download(String filePath, [dynamic filename, dynamic callback]) async {
    // Determine if a custom filename is provided and assign callback accordingly.
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

    // Resolve file path (you might want to adjust this depending on your static folder configuration)
    final file = File(filePath);
    try {
      // Check if the file exists.
      if (!await file.exists()) {
        throw HttpException('File not found');
      }

      // Set the content type to binary and specify the Content-Disposition header for attachment.
      res.headers.contentType = ContentType.binary;
      String dispositionFile = downloadName ?? p.basename(filePath);
      res.headers.set(
        'Content-Disposition',
        'attachment; filename="$dispositionFile"',
      );

      // Pipe the file stream to the response.
      await file.openRead().pipe(res).catchError((err) {
        if (cb != null) cb(err);
      });

      // After completion, call the callback with null (if provided) indicating no error.
      if (cb != null) cb(null);
      if (logger.isActive(LogLevel.info)) {
        DartoLogger.log('File downloaded: $filePath', LogLevel.info);
      }
    } catch (err) {
      // In case of any error, if a callback is provided invoke it with the error.
      if (cb != null) {
        cb(err);
      } else {
        // Otherwise, send an internal server error response.
        res.statusCode = HttpStatus.internalServerError;
        res.write('Error while sending file: $err');
        res.close();
        if (logger.isActive(LogLevel.error)) {
          DartoLogger.log(
              'Error downloading file: $filePath - $err', LogLevel.error);
        }
      }
    }
  }

  /// Sets a cookie on the response.
  ///
  /// Example:
  ///   res.cookie('name', 'tobi', { path: '/admin' });
  void cookie(String name, String value, [Map<String, dynamic>? options]) {
    final opts = options ?? {};
    final buffer = StringBuffer();

    // Base cookie: name=value
    buffer.write('$name=$value');

    // Optional attributes
    if (opts.containsKey('path')) {
      buffer.write('; Path=${opts['path']}');
    } else {
      buffer.write('; Path=/');
    }

    if (opts.containsKey('expires')) {
      // expects a DateTime or a valid cookie date string.
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

    // Add the Set-Cookie header (can be multiple)
    res.headers.add(HttpHeaders.setCookieHeader, buffer.toString());
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Set cookie: $name=$value', LogLevel.info);
    }
  }

  /// Clears a cookie by setting it with an expired date.
  ///
  /// Example:
  ///   res.clearCookie('name', { path: '/admin' });
  void clearCookie(String name, [Map<String, dynamic>? options]) {
    // Merge any provided options with the required expiration date in the past.
    final opts = Map<String, dynamic>.from(options ?? {});
    opts['expires'] = DateTime.fromMillisecondsSinceEpoch(0);
    opts['maxAge'] = 0;
    cookie(name, '', opts);
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Cleared cookie: $name', LogLevel.info);
    }
  }

  /// Redirects the request to a different URL.
  ///
  /// Usage examples:
  ///   res.redirect('/foo/bar')
  ///   res.redirect('http://example.com')
  void redirect(String url) {
    // Set status code to 302 Found by default
    res.statusCode = HttpStatus.found;
    res.headers.set(HttpHeaders.locationHeader, url);
    res.close();
    if (logger.isActive(LogLevel.info)) {
      DartoLogger.log('Redirected to: $url', LogLevel.info);
    }
  }
}
