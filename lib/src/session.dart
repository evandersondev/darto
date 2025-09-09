import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:darto_types/darto_types.dart';

class SessionOptions {
  final String secret;
  final int maxAge; // in seconds
  final bool httpOnly;
  final bool secure;
  final String cookieName;

  SessionOptions({
    required this.secret,
    this.maxAge = 86400,
    this.httpOnly = true,
    this.secure = false,
    this.cookieName = 'darto.sid',
  });
}

class SessionStore {
  static final SessionStore _instance = SessionStore._internal();
  factory SessionStore() => _instance;
  SessionStore._internal();

  final Map<String, Map<String, dynamic>> _sessions = {};
  final Map<String, DateTime> _sessionExpiries = {};

  void set(String sessionId, Map<String, dynamic> data, int maxAge) {
    _sessions[sessionId] = Map<String, dynamic>.from(data); // Cópia defensiva
    _sessionExpiries[sessionId] = DateTime.now().add(Duration(seconds: maxAge));
  }

  Map<String, dynamic>? get(String sessionId) {
    if (_sessionExpiries.containsKey(sessionId)) {
      final expiry = _sessionExpiries[sessionId]!;
      if (expiry.isBefore(DateTime.now())) {
        _sessions.remove(sessionId);
        _sessionExpiries.remove(sessionId);
        return null;
      }
      return Map<String, dynamic>.from(_sessions[sessionId]!);
    }
    return null;
  }

  void destroy(String sessionId) {
    _sessions.remove(sessionId);
    _sessionExpiries.remove(sessionId);
  }
}

class SessionImpl implements Session {
  final Map<String, dynamic> _data;
  final String? _sessionId;
  final SessionStore _store;
  final SessionOptions _options;
  final Response _res;

  SessionImpl(
      this._data, this._sessionId, this._store, this._options, this._res);

  @override
  Map<String, dynamic> get data => _data;

  @override
  dynamic get(String key) => _data[key];

  @override
  void save() {
    if (_sessionId != null) {
      _store.set(_sessionId!, _data, _options.maxAge);
    }
  }

  @override
  void destroy(void Function() callback) {
    if (_sessionId != null) {
      _store.destroy(_sessionId!);
      _res.clearCookie(_options.cookieName, {'path': '/'});
      _data.clear();
    }
    callback();
  }

  @override
  dynamic operator [](String key) => _data[key];

  @override
  void operator []=(String key, dynamic value) => _data[key] = value;
}

Middleware session(SessionOptions options) {
  final store = SessionStore();

  return (Request req, Response res, NextFunction next) async {
    String generateSessionId() {
      final random = Random.secure();
      final bytes = List<int>.generate(16, (_) => random.nextInt(256));
      final time = DateTime.now().millisecondsSinceEpoch.toString();
      final input = utf8.encode(options.secret + time);
      return sha256.convert([...bytes, ...input]).toString().substring(0, 32);
    }

    final cookies = req.cookies;
    String? sessionId = cookies[options.cookieName];

    Map<String, dynamic>? sessionData =
        sessionId != null ? store.get(sessionId) : null;

    if (sessionData == null) {
      sessionId = generateSessionId();
      sessionData = {};
      store.set(sessionId, sessionData, options.maxAge);
      res.cookie(options.cookieName, sessionId, {
        'maxAge': options.maxAge,
        'httpOnly': options.httpOnly,
        'secure': options.secure,
        'path': '/',
      });
    } else {
      res.cookie(options.cookieName, sessionId ?? '', {
        'maxAge': options.maxAge,
        'httpOnly': options.httpOnly,
        'secure': options.secure,
        'path': '/',
      });
    }

    final session = SessionImpl(sessionData, sessionId, store, options, res);
    req.session = session;

    final originalSessionData = Map<String, dynamic>.from(sessionData);

    next();

    bool isSessionModified(
        Map<String, dynamic> original, Map<String, dynamic> current) {
      if (original.length != current.length) {
        return true;
      }
      for (var key in original.keys) {
        if (!current.containsKey(key)) {
          print('Session modified: Missing key $key in current');
          return true;
        }
        if (jsonEncode(original[key]) != jsonEncode(current[key])) {
          return true;
        }
      }
      for (var key in current.keys) {
        if (!original.containsKey(key)) {
          return true;
        }
      }
      return false;
    }

    if (sessionId != null &&
        isSessionModified(originalSessionData, session.data)) {
      store.set(sessionId, session.data, options.maxAge);
    }
  };
}
