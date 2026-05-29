import 'dart:convert';
import 'dart:io';

/// Immutable HTTP response value returned by [Handler].
///
/// Use [Context] helpers — don't construct directly:
///
/// ```dart
/// app.get('/users', (c) => c.ok(users));
/// app.get('/ping',  (c) => c.text('pong'));
/// ```
class Response {
  final int statusCode;
  final dynamic _body;
  final String _contentType;
  final Map<String, String> _extraHeaders;

  /// True when the response was already written directly to the socket
  /// (render, redirect, sendFile). Framework skips dispatch for these.
  final bool alreadySent;

  const Response._raw(
    this.statusCode,
    this._body,
    this._contentType,
    this._extraHeaders,
    this.alreadySent,
  );

  // ── Introspection ─────────────────────────────────────────────────────────

  dynamic get body => _body;
  String get contentType => _contentType;
  Map<String, String> get extraHeaders => Map.unmodifiable(_extraHeaders);

  /// Returns a copy of this response with [key]: [value] merged into its
  /// headers. Used by middleware (e.g. `etag`) to annotate a response without
  /// mutating it.
  Response withHeader(String key, String value) => Response._raw(
        statusCode,
        _body,
        _contentType,
        {..._extraHeaders, key: value},
        alreadySent,
      );

  /// The response body serialized to bytes exactly as [writeTo] would send it.
  /// Returns an empty list for empty / already-sent responses.
  List<int> bodyBytes() {
    if (_body == null) return const [];
    if (_contentType == 'application/json') {
      return utf8.encode(jsonEncode(_encode(_body)));
    }
    if (_body is List<int>) return _body as List<int>;
    return utf8.encode(_body.toString());
  }

  // ── factories ─────────────────────────────────────────────────────────────

  factory Response.json(
    Object body, {
    int status = 200,
    Map<String, String> headers = const {},
  }) =>
      Response._raw(status, body, 'application/json', headers, false);

  factory Response.text(
    String body, {
    int status = 200,
    Map<String, String> headers = const {},
  }) =>
      Response._raw(status, body, 'text/plain; charset=utf-8', headers, false);

  factory Response.html(
    String body, {
    int status = 200,
    Map<String, String> headers = const {},
  }) =>
      Response._raw(status, body, 'text/html; charset=utf-8', headers, false);

  const Response.empty({int status = 204})
      : statusCode = status,
        _body = null,
        _contentType = '',
        _extraHeaders = const {},
        alreadySent = false;

  /// Marker for responses already written directly (render / redirect).
  const Response.sent({int status = 200})
      : statusCode = status,
        _body = null,
        _contentType = '',
        _extraHeaders = const {},
        alreadySent = true;

  // ── dispatch ──────────────────────────────────────────────────────────────

  /// Writes this response to [httpResponse]. No-op when [alreadySent].
  Future<void> writeTo(HttpResponse httpResponse) async {
    if (alreadySent) return;

    httpResponse.statusCode = statusCode;
    _extraHeaders.forEach((k, v) => httpResponse.headers.set(k, v));

    if (_body == null) {
      await httpResponse.close();
      return;
    }

    if (_contentType == 'application/json') {
      httpResponse.headers.contentType = ContentType.json;
      httpResponse.write(jsonEncode(_encode(_body)));
    } else {
      if (_contentType.isNotEmpty) {
        httpResponse.headers.set('Content-Type', _contentType);
      }
      if (_body is List<int>) {
        httpResponse.add(_body as List<int>);
      } else {
        httpResponse.write(_body);
      }
    }

    await httpResponse.close();
  }

  static dynamic _encode(dynamic v) {
    if (v == null) return null;
    if (v is List) return v.map(_encode).toList();
    if (v is Map)
      return v.map((k, val) => MapEntry(k.toString(), _encode(val)));
    if (v is DateTime) return v.toIso8601String();
    return v;
  }

  factory Response.bytes(
    List<int> body, {
    int status = 200,
    String contentType = 'application/octet-stream',
    Map<String, String> headers = const {},
  }) =>
      Response._raw(status, body, contentType, headers, false);
}
