import 'dart:io';

import 'package:darto/darto.dart';

// ── Hop-by-hop header lists (RFC 2616 §13.5.1) ────────────────────────────────

/// Headers removed from the **outgoing** upstream request.
///
/// - Standard hop-by-hop headers that are connection-scoped only.
/// - `host` is stripped so the upstream server uses its own hostname.
/// - `accept-encoding` is removed so [HttpClient.autoUncompress] can inject
///   a compatible value and handle decompression transparently.
const _stripFromRequest = {
  'connection',
  'keep-alive',
  'proxy-authenticate',
  'proxy-authorization',
  'te',
  'trailer',
  'transfer-encoding',
  'upgrade',
  'host',
  'accept-encoding',
};

/// Headers removed from the **upstream response** before it is returned.
///
/// - Hop-by-hop headers are connection-scoped and must not be forwarded.
/// - `content-encoding` is removed because [HttpClient.autoUncompress] has
///   already decoded the body — forwarding it would mislead the client.
/// - `content-length` is removed because the decompressed body size may
///   differ; Dart's HTTP stack recalculates it automatically.
const _stripFromResponse = {
  'connection',
  'keep-alive',
  'proxy-authenticate',
  'proxy-authorization',
  'te',
  'trailer',
  'transfer-encoding',
  'upgrade',
  'content-encoding',
  'content-length',
};

// ── ProxyOptions ──────────────────────────────────────────────────────────────

/// Configuration for the [proxy] helper.
///
/// By default all headers and the request body are forwarded to the upstream
/// server.  Use [headers] to add, replace, or remove individual headers
/// (a `null` value removes that header).  Set [forwardHeaders] or
/// [forwardBody] to `false` to disable automatic forwarding.
///
/// ```dart
/// ProxyOptions(
///   headers: {
///     'Authorization': 'Bearer INTERNAL_TOKEN', // replace
///     'Cookie': null,                            // remove
///   },
/// )
/// ```
class ProxyOptions {
  /// Override the HTTP method. Defaults to the original request method.
  final String? method;

  /// Header overrides applied after the original headers are forwarded.
  ///
  /// A `null` value removes that header from the upstream request.
  final Map<String, String?>? headers;

  /// When `true` (default), original request headers are forwarded to
  /// upstream after stripping hop-by-hop and security-sensitive headers.
  final bool forwardHeaders;

  /// When `true` (default), the original request body is forwarded for
  /// methods that carry a body (`POST`, `PUT`, `PATCH`, `DELETE`).
  final bool forwardBody;

  const ProxyOptions({
    this.method,
    this.headers,
    this.forwardHeaders = true,
    this.forwardBody = true,
  });
}

// ── proxy ─────────────────────────────────────────────────────────────────────

/// Forwards the current request to [url] and returns the upstream response as
/// a Darto [Response].
///
/// - Hop-by-hop headers (Connection, Keep-Alive, Transfer-Encoding, etc.) are
///   automatically stripped from both the outgoing request and the response.
/// - The `Accept-Encoding` header is managed internally so that [HttpClient]
///   can decompress the upstream response transparently.
/// - `Content-Encoding` and `Content-Length` are removed from the forwarded
///   response since the body has already been decoded.
///
/// ```dart
/// // Transparent reverse proxy — forwards method, headers, and body
/// app.all('/api/*', (Context c) =>
///     proxy(c, 'https://backend.com${c.req.path}'));
///
/// // Override auth header and remove cookies
/// app.get('/data', (Context c) async =>
///     proxy(c, 'https://external.com/data',
///         options: ProxyOptions(
///             headers: {
///                 'Authorization': 'Bearer INTERNAL_TOKEN',
///                 'Cookie': null,
///             },
///         ),
///     ),
/// );
/// ```
Future<Response> proxy(
  Context c,
  String url, {
  ProxyOptions? options,
}) async {
  final opts = options ?? const ProxyOptions();
  final method = (opts.method ?? c.req.method).toUpperCase();
  final uri = Uri.parse(url);

  final client = HttpClient()..autoUncompress = true;
  try {
    final upstreamReq = await client.openUrl(method, uri);

    // ── Forward original headers ──────────────────────────────────────────────
    if (opts.forwardHeaders) {
      // Build a set of header keys that the override map will handle, so we
      // don't set them twice.
      final overrideKeys = opts.headers?.keys
              .map((k) => k.toLowerCase())
              .toSet() ??
          const <String>{};

      c.req.headers.forEach((name, value) {
        if (_stripFromRequest.contains(name.toLowerCase())) return;
        if (overrideKeys.contains(name.toLowerCase())) return;
        upstreamReq.headers.set(name, value);
      });
    }

    // ── Apply header overrides ────────────────────────────────────────────────
    if (opts.headers != null) {
      for (final entry in opts.headers!.entries) {
        if (entry.value == null) {
          upstreamReq.headers.removeAll(entry.key);
        } else {
          upstreamReq.headers.set(entry.key, entry.value!);
        }
      }
    }

    // ── Forward body ─────────────────────────────────────────────────────────
    if (opts.forwardBody && _methodHasBody(method)) {
      final body = await c.bodyRaw();
      if (body.isNotEmpty) {
        upstreamReq.contentLength = body.length;
        upstreamReq.add(body);
      }
    }

    // ── Send request and collect response ─────────────────────────────────────
    final upstreamResp = await upstreamReq.close();
    final bytes = await upstreamResp.fold<List<int>>(
      [],
      (buf, chunk) => buf..addAll(chunk),
    );

    // ── Build response headers (strip hop-by-hop) ─────────────────────────────
    final respHeaders = <String, String>{};
    upstreamResp.headers.forEach((name, values) {
      if (!_stripFromResponse.contains(name.toLowerCase())) {
        respHeaders[name] = values.join(', ');
      }
    });

    final ct = upstreamResp.headers.contentType;
    final contentType = ct?.toString() ?? 'application/octet-stream';

    return Response.bytes(
      bytes,
      status: upstreamResp.statusCode,
      contentType: contentType,
      headers: respHeaders,
    );
  } on SocketException {
    // Upstream unreachable (not running, wrong address, firewall, etc.)
    return Response.json(
      {
        'error': 'Bad Gateway',
        'message': 'Upstream service is unavailable',
        'upstream': '${uri.host}:${uri.port}',
      },
      status: 502,
    );
  } on HttpException catch (e) {
    // Upstream returned a malformed HTTP response
    return Response.json(
      {
        'error': 'Bad Gateway',
        'message': e.message,
        'upstream': '${uri.host}:${uri.port}',
      },
      status: 502,
    );
  } finally {
    client.close(force: false);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

bool _methodHasBody(String method) =>
    const {'POST', 'PUT', 'PATCH', 'DELETE'}.contains(method);
