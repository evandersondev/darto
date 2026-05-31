import 'dart:math';

import 'package:darto/darto.dart';

/// Request ID middleware — assigns a unique identifier to each request.
///
/// Honors an incoming [headerName] value when present (useful behind a proxy
/// that already injects one); otherwise generates a UUID v4. The id is stored
/// in the context (read it with [requestIdOf] or `c.get<String>('requestId')`)
/// and echoed back in the response header.
///
/// ```dart
/// import 'package:darto/request_id.dart';
///
/// app.use(requestId());
///
/// app.get('/', [], (c) => c.ok({'id': requestIdOf(c)}));
/// ```
Middleware requestId({
  String headerName = 'X-Request-Id',
  String Function()? generator,
}) {
  return (Context c, Next next) async {
    final incoming = c.req.header(headerName);
    final id = (incoming != null && incoming.isNotEmpty)
        ? incoming
        : (generator ?? _uuidV4)();
    c.set('requestId', id);
    c.header(headerName, id);
    await next();
  };
}

/// Reads the request id set by [requestId]; empty string when absent.
String requestIdOf(Context c) => c.get<String?>('requestId') ?? '';

final _rnd = Random.secure();

/// Generates a RFC 4122 version-4 UUID.
String _uuidV4() {
  final b = List<int>.generate(16, (_) => _rnd.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant 10
  String hex(int start, int end) {
    final sb = StringBuffer();
    for (var i = start; i < end; i++) {
      sb.write(b[i].toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
