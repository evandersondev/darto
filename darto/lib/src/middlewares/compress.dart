import 'dart:convert';
import 'dart:io';

import 'package:darto/darto.dart';

/// Gzip/deflate response compression middleware.
///
/// Compresses responses whose body is at or above [threshold] bytes and whose
/// client advertises the chosen [encoding] in the `Accept-Encoding` header.
/// Already-compressed responses (`Content-Encoding` already set) are skipped.
///
/// ```dart
/// // Defaults: gzip, 1024-byte threshold
/// app.use(compress());
///
/// // Deflate, lower threshold
/// app.use(compress(encoding: 'deflate', threshold: 512));
/// ```
///
/// Supported [encoding] values: `'gzip'` (default), `'deflate'`.
Middleware compress({
  String encoding = 'gzip',
  int threshold = 1024,
}) {
  assert(
    encoding == 'gzip' || encoding == 'deflate',
    'compress: encoding must be "gzip" or "deflate"',
  );

  return (Context c, Next next) async {
    await next();

    final response = c.response;
    if (response == null || response.alreadySent) return;

    // Skip if already compressed
    if (response.extraHeaders.containsKey('content-encoding') ||
        response.extraHeaders.containsKey('Content-Encoding')) return;

    // Skip if client doesn't accept this encoding
    final acceptEncoding = (c.req.header('accept-encoding') ?? '').toLowerCase();
    if (!acceptEncoding.contains(encoding)) return;

    // Convert body → raw bytes
    final bodyBytes = _toBytes(response);
    if (bodyBytes == null || bodyBytes.isEmpty) return;

    // Skip below threshold
    if (bodyBytes.length < threshold) return;

    // Compress
    final compressed = encoding == 'gzip'
        ? GZipCodec().encode(bodyBytes)
        : ZLibCodec().encode(bodyBytes);

    // Merge existing extra-headers, then set compression-specific ones.
    final existingVary = response.extraHeaders['Vary'] ??
        response.extraHeaders['vary'] ??
        '';
    final newVary = existingVary.isEmpty
        ? 'Accept-Encoding'
        : '$existingVary, Accept-Encoding';

    final headers = <String, String>{
      ...response.extraHeaders,
      'Content-Encoding': encoding,
      'Vary': newVary,
      'Content-Length': '${compressed.length}',
    };

    c.respond(Response.bytes(
      compressed,
      status: response.statusCode,
      contentType: response.contentType,
      headers: headers,
    ));
  };
}

// ── Helpers ───────────────────────────────────────────────────────────────────

List<int>? _toBytes(Response r) {
  final b = r.body;
  if (b == null) return null;
  if (b is List<int>) return b;
  if (r.contentType.contains('application/json')) {
    return utf8.encode(jsonEncode(_encodeBody(b)));
  }
  if (b is String) return utf8.encode(b);
  return null;
}

dynamic _encodeBody(dynamic v) {
  if (v == null) return null;
  if (v is List) return v.map(_encodeBody).toList();
  if (v is Map) {
    return v.map((k, val) => MapEntry(k.toString(), _encodeBody(val)));
  }
  if (v is DateTime) return v.toIso8601String();
  return v;
}
