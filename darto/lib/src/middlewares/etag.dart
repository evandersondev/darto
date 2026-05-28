import 'package:crypto/crypto.dart';
import 'package:darto/darto.dart';

/// ETag middleware for **dynamic** responses (handlers, not static files —
/// `darto_static` already handles ETag for files).
///
/// After the handler runs it hashes the response body, sets the `ETag` header,
/// and short-circuits to `304 Not Modified` when the client's `If-None-Match`
/// matches. Applies to `GET`/`HEAD` responses with status `200` and a body.
///
/// ```dart
/// import 'package:darto/etag.dart';
///
/// app.use(etag());
///
/// app.get('/data', [], (c) => c.json({'hello': 'world'}));
/// // → ETag: "<sha1>"; a matching If-None-Match returns 304.
/// ```
///
/// Pass [weak] to emit a weak validator (`W/"…"`).
Middleware etag({bool weak = false}) {
  return (Context c, Next next) async {
    await next();

    final r = c.response;
    if (r == null || r.alreadySent || r.statusCode != 200) return;

    final method = c.req.method.toUpperCase();
    if (method != 'GET' && method != 'HEAD') return;

    final bytes = r.bodyBytes();
    if (bytes.isEmpty) return;

    final hash = sha1.convert(bytes).toString();
    final tag = weak ? 'W/"$hash"' : '"$hash"';

    final ifNoneMatch = c.req.header('if-none-match');
    if (ifNoneMatch != null && _matches(ifNoneMatch, tag, hash)) {
      c.respond(const Response.empty(status: 304).withHeader('ETag', tag));
      return;
    }

    c.respond(r.withHeader('ETag', tag));
  };
}

/// Matches `If-None-Match` against [tag], honoring `*`, comma-separated lists
/// and weak/strong comparison on the underlying [hash].
bool _matches(String ifNoneMatch, String tag, String hash) {
  if (ifNoneMatch.trim() == '*') return true;
  for (var candidate in ifNoneMatch.split(',')) {
    candidate = candidate.trim();
    if (candidate == tag) return true;
    if (candidate.replaceFirst('W/', '') == '"$hash"') return true;
  }
  return false;
}
