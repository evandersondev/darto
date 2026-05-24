import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:darto/darto.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

Middleware serveStatic(
  String folder, {
  String? urlPrefix,
  String? rootDir,
  Duration? maxAge,
  bool enableGzip = false,
}) {
  final prefix = urlPrefix ?? '/$folder';
  final root = rootDir ?? Directory.current.path;
  final baseDir = p.normalize(p.join(root, folder));

  return (Context c, Next next) async {
    final method = c.req.method.toUpperCase();

    if (method != 'GET' && method != 'HEAD') {
      return await next();
    }

    final urlPath = c.req.path;

    if (!urlPath.startsWith(prefix)) {
      return await next();
    }

    final relative =
        urlPath.substring(prefix.length).replaceFirst(RegExp(r'^/'), '');

    final filePath = p.normalize(p.join(baseDir, relative));

    if (!filePath.startsWith(baseDir)) {
      c.forbidden();
      return;
    }

    final file = File(filePath);

    if (!await file.exists()) {
      return await next();
    }

    final stat = await file.stat();
    final lastModified = stat.modified.toUtc();
    final etag = _generateETag(stat);

    // ── Cache headers ──
    if (maxAge != null) {
      c.res.setHeader('Cache-Control', 'public, max-age=${maxAge.inSeconds}');
    }

    c.res.setHeader('ETag', etag);
    c.res.setHeader('Last-Modified', HttpDate.format(lastModified));

    // ── 304 support ──
    final ifNoneMatch = c.req.header('if-none-match');
    final ifModifiedSince = c.req.header('if-modified-since');

    if (ifNoneMatch == etag ||
        (ifModifiedSince != null &&
            DateTime.tryParse(ifModifiedSince)?.isAfter(lastModified) ==
                true)) {
      c.status(304).text('');
      return;
    }

    final mime = lookupMimeType(filePath) ?? 'application/octet-stream';

    final bytes = await file.readAsBytes();

    c.res.setHeader('Content-Type', mime);

    // ── Range requests (video/pdf support) ──
    final range = c.req.header('range');
    if (range != null) {
      final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(range);

      if (match != null) {
        final start = int.parse(match.group(1)!);
        final end = match.group(2)!.isNotEmpty
            ? int.parse(match.group(2)!)
            : bytes.length - 1;

        final chunk = bytes.sublist(start, end + 1);

        c.res.setHeader('Content-Range', 'bytes $start-$end/${bytes.length}');
        c.res.setHeader('Accept-Ranges', 'bytes');

        c.status(206).binary(chunk, contentType: mime);
        return;
      }
    }

    // ── HEAD ──
    if (method == 'HEAD') {
      c.noContent();
      return;
    }

    c.binary(bytes, contentType: mime);
    return;
  };
}

String _generateETag(FileStat stat) {
  final input = '${stat.modified.millisecondsSinceEpoch}-${stat.size}';
  return md5.convert(utf8.encode(input)).toString();
}
