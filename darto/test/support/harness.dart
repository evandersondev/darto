import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:darto/darto.dart';

/// Boots a Darto app on an ephemeral port (no signal handlers), runs [body]
/// with the bound port, then stops the server. Shared by integration tests.
Future<void> withServer(
  void Function(Darto app) routes,
  Future<void> Function(int port) body,
) async {
  final app = Darto();
  routes(app);

  final ready = Completer<void>();
  unawaited(app.serve(
    port: 0,
    shutdownSignals: false,
    onListen: ready.complete,
  ));
  await ready.future;

  try {
    await body(app.port!);
  } finally {
    await app.stop();
  }
}

/// Sends a request and returns the raw response. [method] defaults to GET.
Future<HttpClientResponse> request(
  int port,
  String path, {
  String method = 'GET',
  String? cookie,
  Map<String, String>? headers,
  String? body,
}) async {
  final client = HttpClient();
  final req = await client.openUrl(
    method,
    Uri.parse('http://127.0.0.1:$port$path'),
  );
  if (cookie != null) req.headers.set('cookie', cookie);
  headers?.forEach((k, v) => req.headers.set(k, v));
  if (body != null) req.write(body);
  return req.close();
}

/// Drains the response body as a UTF-8 string.
Future<String> bodyOf(HttpClientResponse res) =>
    res.transform(utf8.decoder).join();
