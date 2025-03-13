import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class Response {
  final HttpResponse res;

  Response(this.res);

  /// Define o status da resposta.
  /// Aceita [statusCode] do tipo int ou um [HttpStatus] da biblioteca dart:io.
  Response status(int statusCode) {
    res.statusCode = statusCode;

    return this;
  }

  /// Envia os dados como resposta e encerra a resposta.
  void send(dynamic data) {
    res.headers.contentType = ContentType.text;
    res.write(jsonEncode(data));
    res.close();
  }

  /// Envia os dados como resposta e encerra a resposta.
  void json(dynamic data) {
    res.headers.contentType = ContentType.json;
    res.write(jsonEncode(data));
    res.close();
  }

  /// Encerra a resposta.
  /// Se [data] for passado, ele será escrito antes de fechar a conexão.
  void end([dynamic data]) {
    if (data != null) {
      res.write(data);
    }
    res.close();
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
    } catch (err) {
      // In case of any error, if a callback is provided invoke it with the error.
      if (cb != null) {
        cb(err);
      } else {
        // Otherwise, send an internal server error response.
        res.statusCode = HttpStatus.internalServerError;
        res.write('Error while sending file: $err');
        res.close();
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
  }
}
