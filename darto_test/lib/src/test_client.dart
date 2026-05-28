import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:darto/darto.dart';

/// A test client that boots a [Darto] app on an ephemeral loopback port and
/// drives it with HTTP requests.
///
/// Create one per test (or per group) with [TestClient.create], make requests
/// with [get] / [post] / [request] / …, and release it with [close].
class TestClient {
  /// The app under test.
  final Darto app;

  /// The ephemeral port the app is bound to.
  final int port;

  final HttpClient _http = HttpClient();

  TestClient._(this.app, this.port);

  /// Boots [app] on a free loopback port (no shutdown signals) and returns a
  /// client bound to it. Register the app's routes before calling this.
  static Future<TestClient> create(Darto app) async {
    final ready = Completer<void>();
    unawaited(app.serve(
      port: 0,
      host: InternetAddress.loopbackIPv4,
      shutdownSignals: false,
      onListen: ready.complete,
    ));
    await ready.future;
    return TestClient._(app, app.port!);
  }

  /// Sends a request and returns the captured [TestResponse].
  ///
  /// Pass [json] to send a JSON body (sets `Content-Type: application/json`),
  /// or [body] for a raw `String` / `List<int>` payload.
  Future<TestResponse> request(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
    Object? json,
    bool followRedirects = true,
  }) async {
    final req = await _http.openUrl(
      method.toUpperCase(),
      Uri.parse('http://${InternetAddress.loopbackIPv4.address}:$port$path'),
    );
    req.followRedirects = followRedirects;
    headers?.forEach((k, v) => req.headers.set(k, v));

    if (json != null) {
      req.headers.contentType =
          ContentType('application', 'json', charset: 'utf-8');
      req.write(jsonEncode(json));
    } else if (body is List<int>) {
      req.add(body);
    } else if (body != null) {
      req.write(body.toString());
    }

    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();

    final headerMap = <String, String>{};
    res.headers.forEach((name, values) {
      headerMap[name.toLowerCase()] = values.join(', ');
    });

    return TestResponse._(res.statusCode, headerMap, res.cookies, text);
  }

  Future<TestResponse> get(
    String path, {
    Map<String, String>? headers,
    bool followRedirects = true,
  }) =>
      request('GET', path, headers: headers, followRedirects: followRedirects);

  Future<TestResponse> head(String path, {Map<String, String>? headers}) =>
      request('HEAD', path, headers: headers);

  Future<TestResponse> options(String path, {Map<String, String>? headers}) =>
      request('OPTIONS', path, headers: headers);

  Future<TestResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Object? json,
  }) =>
      request('POST', path, headers: headers, body: body, json: json);

  Future<TestResponse> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Object? json,
  }) =>
      request('PUT', path, headers: headers, body: body, json: json);

  Future<TestResponse> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Object? json,
  }) =>
      request('PATCH', path, headers: headers, body: body, json: json);

  Future<TestResponse> delete(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Object? json,
  }) =>
      request('DELETE', path, headers: headers, body: body, json: json);

  /// Closes the client and stops the app.
  Future<void> close() async {
    _http.close(force: true);
    await app.stop();
  }
}

/// A captured response from a [TestClient] request.
class TestResponse {
  /// The HTTP status code.
  final int statusCode;

  /// Response headers, with lowercased names and multi-values joined by `, `.
  final Map<String, String> headers;

  /// Cookies parsed from `Set-Cookie`.
  final List<Cookie> cookies;

  /// The raw response body decoded as UTF-8 text.
  final String body;

  TestResponse._(this.statusCode, this.headers, this.cookies, this.body);

  /// The body parsed as JSON (`null` when the body is empty).
  dynamic get json => body.isEmpty ? null : jsonDecode(body);

  /// Returns the header [name] (case-insensitive), or `null`.
  String? header(String name) => headers[name.toLowerCase()];

  /// Returns the value of the `Set-Cookie` cookie [name], or `null`.
  String? cookie(String name) {
    for (final c in cookies) {
      if (c.name == name) return c.value;
    }
    return null;
  }

  /// `true` for 2xx status codes.
  bool get isOk => statusCode >= 200 && statusCode < 300;

  @override
  String toString() => 'TestResponse($statusCode, ${body.length} bytes)';
}
