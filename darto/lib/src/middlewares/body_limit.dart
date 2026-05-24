import 'package:darto/darto.dart';

/// Body size limit middleware.
///
/// Rejects requests whose body exceeds [maxSize] bytes before the handler
/// runs. Uses the `Content-Length` header as a fast path when available;
/// falls back to buffering the body stream and checking the accumulated size.
///
/// The [onError] callback receives the [Context] and must return a [Response].
/// When omitted, a plain `413 Payload Too Large` text response is sent.
///
/// ```dart
/// app.post(
///   '/upload',
///   (c) async {
///     final body = await c.body();
///     return c.text('pass :)');
///   },
///   [bodyLimit(
///     maxSize: 50 * 1024, // 50 KB
///     onError: (c) => c.text('overflow :(', 413),
///   )],
/// );
/// ```
Middleware bodyLimit({
  required int maxSize,
  Handler? onError,
}) {
  Future<void> reject(Context c) async {
    if (onError != null) {
      await onError(c);
    } else {
      c.status(413).text('Payload Too Large');
    }
  }

  return (Context c, Next next) async {
    // ── Fast path: Content-Length header ──────────────────────────────────────
    final rawLength = c.req.header('content-length');
    if (rawLength != null) {
      final declared = int.tryParse(rawLength);
      if (declared != null && declared > maxSize) {
        await reject(c);
        return;
      }
    }

    // ── Slow path: buffer the body and measure ────────────────────────────────
    // bodyRaw() caches the bytes on DartoRequest, so the handler can still
    // call c.body() / c.bodyRaw() normally after this check passes.
    final bytes = await c.bodyRaw();
    if (bytes.length > maxSize) {
      await reject(c);
      return;
    }

    await next();
  };
}
