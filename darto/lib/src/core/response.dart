part of 'darto_base.dart';

class DartoResponse {
  final HttpResponse _res;
  bool _finished = false;
  bool get finished => _finished;

  DartoResponse(this._res);

  void set(String key, String value) => _res.headers.set(key, value);

  void redirect(String url, [int status = 302]) {
    _res.statusCode = status;
    _res.headers.set(HttpHeaders.locationHeader, url);
    _res.close();
    _finished = true;
  }

  // ── Headers ───────────────────────────────────────────────────────────────

  String? header(String key) => _res.headers.value(key);
  void setHeader(String key, String v) => set(key, v);

  // ── Streaming ─────────────────────────────────────────────────────────────

  /// Exposes the underlying [HttpResponse] for streaming helpers.
  HttpResponse get raw => _res;
}
