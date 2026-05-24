import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:darto/darto.dart';
import 'package:darto/cookie.dart';

const _sessionDataKey = '__darto_session_data__';
const _sessionCtrlKey = '__darto_session_ctrl__';

class SessionController {
  final Context _c;
  final String _secret;
  final int _duration;
  final String _cookieName;

  SessionController(this._c, this._secret, this._duration, this._cookieName);

  /// Returns the current session data, or null if no active session.
  Map<String, dynamic>? get() => _c.get<Map<String, dynamic>>(_sessionDataKey);

  /// Replaces the session data and writes the signed cookie to the response.
  Future<void> update(Map<String, dynamic> data) async {
    _c.set(_sessionDataKey, data);
    final payload = base64UrlEncode(utf8.encode(jsonEncode(data)));
    final sig = _sign(payload, _secret);
    setCookie(
      _c,
      _cookieName,
      '$payload.$sig',
      CookieOptions(httpOnly: true, sameSite: 'Lax', maxAge: _duration),
    );
  }

  /// Clears the session and deletes the cookie.
  void delete() {
    _c.set(_sessionDataKey, null);
    deleteCookie(_c, _cookieName);
  }
}

/// Middleware that reads and validates the signed session cookie on every request.
///
/// Register once globally; then use [sessionContext] in any handler.
///
/// ```dart
/// import 'package:darto/session.dart';
///
/// app.use(sessionMiddleware(secret: 'at-least-32-chars-long-secret!!'));
///
/// app.get('/login', [], (c) async {
///   final session = sessionContext(c);
///   await session.update({'userId': '42', 'role': 'admin'});
///   return c.ok({'message': 'logged in'});
/// });
///
/// app.get('/me', [], (c) async {
///   final data = sessionContext(c).get();
///   if (data == null) return c.unauthorized({'error': 'no session'});
///   return c.ok(data);
/// });
///
/// app.get('/logout', [], (c) async {
///   sessionContext(c).delete();
///   return c.ok({'message': 'logged out'});
/// });
/// ```
Middleware sessionMiddleware({
  required String secret,
  int duration = 1800,
  String cookieName = 'darto.session',
}) {
  return (Context c, Next next) async {
    final raw = getCookie(c, cookieName);
    if (raw != null) {
      final dot = raw.lastIndexOf('.');
      if (dot > 0) {
        final payload = raw.substring(0, dot);
        final sig = raw.substring(dot + 1);
        if (sig == _sign(payload, secret)) {
          try {
            final json = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
            final data = jsonDecode(json);
            if (data is Map<String, dynamic>) {
              c.set(_sessionDataKey, data);
            }
          } catch (_) {}
        }
      }
    }
    c.set(_sessionCtrlKey, SessionController(c, secret, duration, cookieName));
    await next();
  };
}

/// Returns the [SessionController] for the current request.
///
/// Throws [StateError] if [sessionMiddleware] was not registered.
SessionController sessionContext(Context c) {
  final ctrl = c.get<SessionController?>(_sessionCtrlKey);
  if (ctrl == null) {
    throw StateError(
      'sessionContext() called without sessionMiddleware. '
      'Register app.use(sessionMiddleware(...)) before using sessions.',
    );
  }
  return ctrl;
}

String _sign(String value, String secret) {
  final hmac = Hmac(sha256, utf8.encode(secret));
  return base64UrlEncode(hmac.convert(utf8.encode(value)).bytes);
}
