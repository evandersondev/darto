import 'dart:io';

/// Represents the headers of a request or response.
///
/// This class provides methods to access and manipulate the headers of a request or response.
class DartoHeader {
  final HttpHeaders _headers;

  DartoHeader(this._headers);

  /// Returns the value of the 'authorization' header.
  String? get authorization => _headers.value(HttpHeaders.authorizationHeader);

  /// Returns the value of a specified header.
  String? get(String name) => _headers.value(name);

  void append(String name, String value) {
    _headers.set(name, value);
  }

  /// Returns all headers as a map.
  Map<String, List<String>> get allHeaders {
    final headersMap = <String, List<String>>{};
    _headers.forEach((name, values) {
      headersMap[name] = values;
    });
    return headersMap;
  }
}
