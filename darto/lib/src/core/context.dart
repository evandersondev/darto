part of 'darto_base.dart';

class Context {
  final DartoRequest _req;
  final DartoResponse _res;
  Response? _response;

  List<RouteSpec> _matchedRoutes = const [];
  String? _routePath;
  String? _baseRoutePath;
  String? _basePath;

  Context(this._req, this._res);

  // ── Route metadata ────────────────────────────────────────────────────────

  /// All routes that matched the current request (middleware + handler).
  List<RouteSpec> get matchedRoutes => _matchedRoutes;

  /// The registered pattern of the matched handler route (e.g. `/posts/:id`).
  String? get routePath => _routePath;

  /// The group prefix pattern of the matched route (e.g. `/api`).
  String? get baseRoutePath => _baseRoutePath;

  /// The resolved base path with actual URL values (e.g. `/acme` for `/:tenant`).
  String? get basePath => _basePath;

  // ── Request ───────────────────────────────────────────────────────────────
  DartoRequest get req => _req;
  DartoResponse get res => _res;
  Future<T> body<T>([T Function(Map<String, dynamic>)? fromJson]) =>
      _req.json<T>(fromJson);
  Future<List<int>> bodyRaw() async => (await _req.blob()).toList();

  // ── State ─────────────────────────────────────────────────────────────────

  void set(String key, dynamic value) => _req.set(key, value);
  T get<T>(String key) => _req.get(key) as T;

  /// The HTTP status code of the current response.
  /// Returns `200` when no response has been set yet.
  int get statusCode => _response?.statusCode ?? 200;

  /// The current [Response] set by a handler or middleware, or `null` if none
  /// has been set yet (i.e. before [next] completes).
  Response? get response => _response;

  /// Sets an arbitrary [Response] directly — useful for cache-hit scenarios
  /// where the full response object is already available.
  void respond(Response r) { _r(r); }

  /// Clears the current response.
  ///
  /// Used by middleware combiners (e.g. [some]) to reset a rejection
  /// response set by a failed sub-middleware before trying the next one.
  void clearResponse() { _response = null; }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Map<String, dynamic>? get user {
    final u = _req.get('user');
    return u == null ? null : Map<String, dynamic>.from(u as Map);
  }

  set user(Map<String, dynamic>? value) => _req.set('user', value);

  // ── Validation ────────────────────────────────────────────────────────────

  T validated<T>([String key = 'validated']) => _req.get(key) as T;

  // ── Response helpers ──────────────────────────────────────────────────────

  Response _r(Response r) {
    _response = r;
    return r;
  }

  Response json(dynamic data, [int status = 200]) =>
      _r(Response.json(data, status: status));
  Response text(String data, [int status = 200]) =>
      _r(Response.text(data, status: status));
  Response html(String data, [int status = 200]) =>
      _r(Response.html(data, status: status));

  PendingResponse status(int code) => PendingResponse._(this, code);

  Response ok([dynamic body]) =>
      _r(Response.json(body ?? const {}, status: 200));
  Response created([dynamic body]) =>
      _r(Response.json(body ?? const {}, status: 201));
  Response noContent() => _r(const Response.empty(status: 204));
  Response badRequest([dynamic body]) =>
      _r(Response.json(body ?? const {'error': 'Bad Request'}, status: 400));
  Response unauthorized([dynamic body]) =>
      _r(Response.json(body ?? const {'error': 'Unauthorized'}, status: 401));
  Response forbidden([dynamic body]) =>
      _r(Response.json(body ?? const {'error': 'Forbidden'}, status: 403));
  Response notFound([dynamic body]) =>
      _r(Response.json(body ?? const {'error': 'Not Found'}, status: 404));
  Response conflict([dynamic body]) =>
      _r(Response.json(body ?? const {'error': 'Conflict'}, status: 409));
  Response internalError([dynamic body]) =>
      _r(Response.json(body ?? const {'error': 'Internal Server Error'},
          status: 500));

  Response redirect(String url, [int status = 302]) {
    _res.redirect(url, status);
    return _r(const Response.sent());
  }

  Response binary(
    List<int> bytes, {
    int status = 200,
    String? contentType,
  }) {
    return _r(Response.bytes(
      bytes,
      status: status,
      contentType: contentType ?? 'application/octet-stream',
    ));
  }

  Future<Response> file(
    String path, {
    String? contentType,
  }) async {
    final f = File(path);
    if (!await f.exists()) return notFound();

    final stat = await f.stat();
    final mime = contentType ?? lookupMimeType(path) ?? 'application/octet-stream';
    final httpRes = _res.raw;

    httpRes.statusCode = 200;
    httpRes.headers.set('Content-Type', mime);
    httpRes.headers.set('Content-Length', '${stat.size}');

    await f.openRead().pipe(httpRes);
    return _r(const Response.sent());
  }

  Future<Response> download(
    String path, {
    String? filename,
  }) async {
    final f = File(path);
    if (!await f.exists()) return notFound();

    final stat = await f.stat();
    final name = filename ?? path.split('/').last;
    final mime = lookupMimeType(path) ?? 'application/octet-stream';
    final httpRes = _res.raw;

    httpRes.statusCode = 200;
    httpRes.headers.set('Content-Type', mime);
    httpRes.headers.set('Content-Length', '${stat.size}');
    httpRes.headers.set('Content-Disposition', 'attachment; filename="$name"');

    await f.openRead().pipe(httpRes);
    return _r(const Response.sent());
  }

  void header(String key, String value) => _res.setHeader(key, value);

  // ── Render ────────────────────────────────────────────────────────────────

  RenderLayout? _renderLayout;

  /// Registers an HTML layout function for this request.
  ///
  /// Typically called in a global or path-scoped middleware so every handler
  /// on that path can call [render] and get a consistently wrapped response.
  ///
  /// The [layout] receives the inner HTML string produced by the handler plus
  /// an optional [props] map (page title, meta data, etc.) and must return a
  /// `Response` — usually via `c.html(...)`.
  ///
  /// ```dart
  /// app.use((Context c, Next next) async {
  ///   c.setRender((content, props) => c.html('''
  ///     <!DOCTYPE html>
  ///     <html>
  ///       <head><title>${props['title'] ?? 'Darto'}</title></head>
  ///       <body>$content</body>
  ///     </html>
  ///   '''));
  ///   await next();
  /// });
  /// ```
  void setRender(RenderLayout layout) {
    _renderLayout = layout;
  }

  /// Renders [content] using the layout registered via [setRender].
  ///
  /// The optional [props] map is forwarded to the layout and can carry
  /// per-page data such as the page title or Open Graph tags.
  ///
  /// When no layout has been set, returns a plain `text/html` response with
  /// [content] as the body.
  ///
  /// ```dart
  /// app.get('/', (Context c) {
  ///   return c.render('<h1>Hello</h1>', {'title': 'Home'});
  /// });
  ///
  /// app.get('/about', (Context c) {
  ///   return c.render('<p>About us</p>', {'title': 'About'});
  /// });
  /// ```
  Future<Response> render(
    String content, [
    Map<String, dynamic> props = const {},
  ]) async {
    if (_renderLayout != null) {
      final result = _renderLayout!(content, props);
      return result is Future<Response> ? await result : result;
    }
    return html(content);
  }
}

class PendingResponse {
  final Context _c;
  final int _status;
  PendingResponse._(this._c, this._status);

  Response json(dynamic data) => _c._r(Response.json(data, status: _status));
  Response text(String data) => _c._r(Response.text(data, status: _status));
  Response html(String data) => _c._r(Response.html(data, status: _status));
  Response binary(
    List<int> bytes, {
    String? contentType,
  }) =>
      _c._r(Response.bytes(
        bytes,
        status: _status,
        contentType: contentType ?? 'application/octet-stream',
      ));
}
