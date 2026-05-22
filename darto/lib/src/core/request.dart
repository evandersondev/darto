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

  Future<ByteBuffer> arrayBuffer() async {
    final bytes = await blob();
    return bytes.buffer;
  }

  Future<dynamic> formData() async {
    final contentType = _req.headers.contentType?.mimeType ?? "";
    final text = await _bodyText();
    if (contentType == "application/x-www-form-urlencoded") {
      return Uri.splitQueryString(text);
    }
    // Para multipart/form-data, uma implementação mais completa é necessária.
    return text;
  }

  Future<String> _bodyText() async {
    final bytes = await _readBytes();
    return utf8.decode(bytes);
  }

  // ── Raw stream ────────────────────────────────────────────────────────────

  /// The raw body stream of the HTTP request.
  ///
  /// Consumed once — do not mix with [blob] / [json] on the same request.
  /// Used by [Upload] middleware and [parseBody] for streaming multipart parsing.
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
      final text = await _bodyText();
      return Uri.splitQueryString(text).cast<String, dynamic>();
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
