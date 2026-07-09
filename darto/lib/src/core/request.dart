part of 'darto_base.dart';

// ── UploadedFile ──────────────────────────────────────────────────────────────

/// A file received via `multipart/form-data`, returned by [DartoRequest.parseBody].
///
/// When [parseBody] is called without `saveDir`, the file is kept in [bytes].
/// When `saveDir` is provided, the file is streamed to disk and [path] is set
/// while [bytes] is empty — use [isOnDisk] to distinguish.
///
/// ```dart
/// // In-memory
/// final body = await c.req.parseBody();
/// final file = body['avatar'] as UploadedFile;
/// print(file.bytes.length);
///
/// // Saved to disk
/// final body = await c.req.parseBody(saveDir: 'uploads');
/// final file = body['avatar'] as UploadedFile;
/// print(file.path);   // uploads/1716123456789_photo_482910374.jpg
/// print(file.size);
/// ```
class UploadedFile {
  final String fieldname;
  final String name;
  final Uint8List bytes;
  final String mimeType;
  final String? path;
  final int size;

  bool get isOnDisk => path != null;

  const UploadedFile({
    required this.fieldname,
    required this.name,
    required this.bytes,
    required this.mimeType,
    required this.size,
    this.path,
  });
}

// ── DartoRequest ─────────────────────────────────────────────────────────────

class DartoRequest {
  final HttpRequest _req;
  final Map<String, String> _params;
  final Map<String, dynamic> _ctx = {};

  bool _bodyRead = false;
  Map<String, dynamic>? _cachedBody;
  Uint8List? _cachedBytes;

  DartoRequest(this._req, this._params);

  Uri get url => _req.uri;
  String get method => _req.method;
  String get path => _req.uri.path;
  String get ip => _req.connectionInfo?.remoteAddress.address ?? '';

  // ── Params ────────────────────────────────────────────────────────────────

  String? param(String key) => _params[key];
  int? paramInt(String key) => int.tryParse(_params[key] ?? '');
  double? paramDouble(String key) => double.tryParse(_params[key] ?? '');

  List<String?> params() {
    return _params.values.toList();
  }

  /// All route path parameters as an unmodifiable [Map].
  Map<String, String> get paramsMap => Map.unmodifiable(_params);

  // ── Headers ───────────────────────────────────────────────────────────────

  String? header(String key) => _req.headers.value(key);
  void setHeader(String key, String v) => set(key, v);

  /// All request headers as an unmodifiable [Map].
  /// Multi-value headers are joined with `', '`.
  Map<String, String> get headers {
    final result = <String, String>{};
    _req.headers.forEach((name, values) {
      result[name] = values.join(', ');
    });
    return Map.unmodifiable(result);
  }

// ── Query ─────────────────────────────────────────────────────────────────

  String? query(String key) => _req.uri.queryParameters[key];
  List<String> queries() => _req.uri.queryParameters.values.toList();
  int? queryInt(String key) =>
      int.tryParse(_req.uri.queryParameters[key] ?? '');
  double? queryDouble(String key) =>
      double.tryParse(_req.uri.queryParameters[key] ?? '');
  bool queryBool(String key) {
    final v = (_req.uri.queryParameters[key] ?? '').toLowerCase();
    return const {'true', '1', 'yes', 'on'}.contains(v);
  }

  // ── Content negotiation ─────────────────────────────────────────────────────

  /// Returns the best match from [types] against the request `Accept` header,
  /// honoring quality (`q`) values — HonoJS / Express-style `c.req.accepts()`.
  ///
  /// [types] are the media types the handler can produce, in the server's order
  /// of preference (used to break ties when the client rates two equally).
  ///
  /// Returns `null` when the client accepts none of [types].
  ///
  /// ```dart
  /// switch (c.req.accepts(['application/json', 'text/html'])) {
  ///   case 'text/html':
  ///     return c.html('<b>hi</b>');
  ///   default:
  ///     return c.json({'ok': true});
  /// }
  /// ```
  ///
  /// A missing or empty `Accept` header means "accept anything" — the first
  /// entry of [types] is returned.
  String? accepts(List<String> types) {
    if (types.isEmpty) return null;
    final header = _req.headers.value('accept');
    if (header == null || header.trim().isEmpty) return types.first;

    final ranges = _parseAccept(header);
    if (ranges.isEmpty) return types.first;

    String? best;
    double bestQ = -1;
    // Preserve the server's preference order: iterate [types] and keep the one
    // with the highest client q-value (first-wins on ties).
    for (final type in types) {
      final q = _matchQuality(type, ranges);
      if (q > bestQ) {
        bestQ = q;
        best = type;
      }
    }
    return bestQ > 0 ? best : null;
  }

  /// Parses an `Accept` header into `(type, subtype, q)` records, most
  /// specific first is *not* guaranteed — callers score against all of them.
  static List<({String type, String subtype, double q})> _parseAccept(
    String header,
  ) {
    final result = <({String type, String subtype, double q})>[];
    for (final part in header.split(',')) {
      final segs = part.split(';');
      final media = segs.first.trim();
      if (media.isEmpty) continue;
      final slash = media.indexOf('/');
      final type = slash >= 0 ? media.substring(0, slash) : media;
      final subtype = slash >= 0 ? media.substring(slash + 1) : '*';

      double q = 1.0;
      for (var i = 1; i < segs.length; i++) {
        final param = segs[i].trim();
        if (param.startsWith('q=')) {
          q = double.tryParse(param.substring(2)) ?? 1.0;
        }
      }
      result.add((type: type, subtype: subtype, q: q));
    }
    return result;
  }

  /// The q-value the client assigns to [candidate] given the parsed [ranges].
  /// Returns `0` when no range matches (including explicit `q=0` rejection).
  static double _matchQuality(
    String candidate,
    List<({String type, String subtype, double q})> ranges,
  ) {
    final slash = candidate.indexOf('/');
    final cType = slash >= 0 ? candidate.substring(0, slash) : candidate;
    final cSub = slash >= 0 ? candidate.substring(slash + 1) : '*';

    double best = 0;
    var bestSpecificity = -1;
    for (final r in ranges) {
      final typeOk = r.type == '*' || r.type == cType;
      final subOk = r.subtype == '*' || r.subtype == cSub;
      if (!typeOk || !subOk) continue;
      // Prefer the most specific matching range (exact > type/* > */*).
      final specificity =
          (r.type == '*' ? 0 : 2) + (r.subtype == '*' ? 0 : 1);
      if (specificity > bestSpecificity) {
        bestSpecificity = specificity;
        best = r.q;
      }
    }
    return best;
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Future<Uint8List> _readBytes() async {
    if (_cachedBytes != null) return _cachedBytes!;
    final b = BytesBuilder(copy: false);
    await for (final chunk in _req) b.add(chunk);
    return _cachedBytes = b.takeBytes();
  }

  Future<T> json<T>([T Function(Map<String, dynamic>)? fromJson]) async {
    if (!_bodyRead) {
      _bodyRead = true;
      final bytes = await _readBytes();
      final raw = utf8.decode(bytes);
      final ct = _req.headers.contentType?.mimeType;
      if (ct == 'application/json' && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        _cachedBody = decoded is Map<String, dynamic>
            ? decoded
            : decoded is Map
                ? decoded.cast<String, dynamic>()
                : {};
      } else if (ct == 'application/x-www-form-urlencoded') {
        _cachedBody = Uri.splitQueryString(raw).cast<String, dynamic>();
      } else {
        _cachedBody = {};
      }
    }
    final map = _cachedBody ?? {};
    if (fromJson != null) return fromJson(map);
    return map as T;
  }

  Future<Uint8List> blob() => _readBytes();

  dynamic get(String key) => _ctx[key];
  void set(String key, dynamic v) => _ctx[key] = v;

  /// Retrieves the value stored by `validator()` or `zValidator()` for [target].
  ///
  /// Must be called in a handler that runs after one of those middlewares.
  ///
  /// ```dart
  /// app.post('/users', [zValidator('json', schema)], (c) {
  ///   final data = c.req.valid<Map<String, dynamic>>('json');
  /// });
  /// ```
  T valid<T>(String target) => get('__v_$target') as T;

  Future<ByteBuffer> arrayBuffer() async {
    final bytes = await blob();
    return bytes.buffer;
  }

  Future<dynamic> formData() async {
    final contentType = _req.headers.contentType?.mimeType ?? "";
    final body = await text();
    if (contentType == "application/x-www-form-urlencoded") {
      return Uri.splitQueryString(body);
    }
    // Para multipart/form-data, uma implementação mais completa é necessária.
    return body;
  }

  /// The request body decoded as UTF-8 text — HonoJS-style `c.req.text()`.
  Future<String> text() async {
    final bytes = await _readBytes();
    return utf8.decode(bytes);
  }

  // ── Raw stream ────────────────────────────────────────────────────────────

  /// The raw request body stream — HonoJS-style `c.req.body`.
  ///
  /// Consumed once — do not mix with [blob] / [json] / [text] on the same
  /// request. Used by [Upload] middleware and [parseBody] for streaming
  /// multipart parsing.
  Stream<List<int>> get body => _req;

  /// Alias of [body], kept for backward compatibility.
  Stream<List<int>> get rawStream => _req;

  /// The underlying [HttpRequest] — used by protocol-upgrade handlers such as
  /// WebSocket. Prefer the typed helpers for regular request data.
  HttpRequest get raw => _req;

  // ── parseBody ─────────────────────────────────────────────────────────────

  /// Parses the request body into a flat map — HonoJS-style.
  ///
  /// | Content-Type                        | Value type                     |
  /// |-------------------------------------|--------------------------------|
  /// | `application/json`                  | `Map<String, dynamic>`         |
  /// | `application/x-www-form-urlencoded` | `String` per field             |
  /// | `multipart/form-data`               | `String` or [UploadedFile]     |
  ///
  /// When multiple parts share the same field name the value becomes a `List`.
  ///
  /// Pass `saveDir` to stream files directly to disk without buffering them in
  /// memory — recommended for large uploads (videos, documents, etc.).
  ///
  /// ```dart
  /// // In-memory (small files)
  /// app.post('/avatar', (c) async {
  ///   final body = await c.req.parseBody();
  ///   final file = body['avatar'] as UploadedFile;
  ///   return c.ok({'size': file.size});
  /// });
  ///
  /// // Streamed to disk (large files)
  /// app.post('/video', (c) async {
  ///   final body = await c.req.parseBody(saveDir: 'uploads');
  ///   final file = body['video'] as UploadedFile;
  ///   return c.ok({'path': file.path, 'size': file.size});
  /// });
  /// ```
  Future<Map<String, dynamic>> parseBody({String? saveDir}) async {
    final ct = _req.headers.contentType;
    final mime = ct?.mimeType ?? '';

    if (mime == 'application/json') {
      return await json();
    }

    if (mime == 'application/x-www-form-urlencoded') {
      final raw = await text();
      return Uri.splitQueryString(raw).cast<String, dynamic>();
    }

    if (mime == 'multipart/form-data') {
      final boundary = ct?.parameters['boundary'] ?? '';
      if (boundary.isEmpty) return {};

      Directory? uploadDir;
      if (saveDir != null) {
        uploadDir = Directory(saveDir);
        if (!uploadDir.existsSync()) uploadDir.createSync(recursive: true);
      }

      final result = <String, dynamic>{};
      final parts = _req
          .cast<List<int>>()
          .transform(MimeMultipartTransformer(boundary));

      await for (final part in parts) {
        final disposition = part.headers['content-disposition'] ?? '';
        final fieldname =
            RegExp(r'name="([^"]*)"').firstMatch(disposition)?.group(1);
        if (fieldname == null) continue;

        final filename =
            RegExp(r'filename="([^"]*)"').firstMatch(disposition)?.group(1);

        if (filename != null) {
          final partMime =
              part.headers['content-type'] ?? 'application/octet-stream';

          if (uploadDir != null) {
            final savedPath = _uniquePath(uploadDir.path, filename);
            final sink = File(savedPath).openWrite();
            await part.pipe(sink);
            final fileSize = await File(savedPath).length();
            _merge(
              result,
              fieldname,
              UploadedFile(
                fieldname: fieldname,
                name: filename,
                bytes: Uint8List(0),
                mimeType: partMime,
                size: fileSize,
                path: savedPath,
              ),
            );
          } else {
            final buf = BytesBuilder(copy: false);
            await for (final chunk in part) buf.add(chunk);
            final bytes = buf.takeBytes();
            _merge(
              result,
              fieldname,
              UploadedFile(
                fieldname: fieldname,
                name: filename,
                bytes: bytes,
                mimeType: partMime,
                size: bytes.length,
              ),
            );
          }
        } else {
          final buf = BytesBuilder(copy: false);
          await for (final chunk in part) buf.add(chunk);
          _merge(result, fieldname, utf8.decode(buf.takeBytes()));
        }
      }

      return result;
    }

    return {};
  }

  static String _uniquePath(String dir, String filename) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rnd = Random().nextInt(999999999);
    final dot = filename.lastIndexOf('.');
    final ext = dot >= 0 ? filename.substring(dot) : '';
    final base = dot >= 0 ? filename.substring(0, dot) : filename;
    return '$dir/${ts}_${base}_$rnd$ext';
  }

  static void _merge(Map<String, dynamic> map, String key, dynamic value) {
    if (!map.containsKey(key)) {
      map[key] = value;
    } else {
      final existing = map[key];
      if (existing is List) {
        existing.add(value);
      } else {
        map[key] = [existing, value];
      }
    }
  }
}
