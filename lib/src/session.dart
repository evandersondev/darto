import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:darto_types/darto_types.dart';

class SessionOptions {
  final String secret;
  final int maxAge; // em segundos
  final bool httpOnly;
  final bool secure;
  final String cookieName;

  SessionOptions({
    required this.secret,
    this.maxAge = 86400, // 24 horas por padrão
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
    _sessions[sessionId] = data; // Usar referência direta
    _sessionExpiries[sessionId] = DateTime.now().add(Duration(seconds: maxAge));
    print(
        'SessionStore set: $sessionId -> ${_sessions[sessionId]}'); // Log de depuração
  }

  Map<String, dynamic>? get(String sessionId) {
    if (_sessionExpiries.containsKey(sessionId)) {
      final expiry = _sessionExpiries[sessionId]!;
      if (expiry.isBefore(DateTime.now())) {
        _sessions.remove(sessionId);
        _sessionExpiries.remove(sessionId);
        print('SessionStore get: $sessionId expired'); // Log de depuração
        return null;
      }
      print(
          'SessionStore get: $sessionId -> ${_sessions[sessionId]}'); // Log de depuração
      return _sessions[sessionId]; // Retornar referência direta
    }
    print('SessionStore get: $sessionId not found'); // Log de depuração
    return null;
  }

  void destroy(String sessionId) {
    _sessions.remove(sessionId);
    _sessionExpiries.remove(sessionId);
    print('SessionStore destroy: $sessionId'); // Log de depuração
  }
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

    // Obter o ID da sessão a partir do cookie
    final cookies = req.cookies;
    String? sessionId = cookies[options.cookieName];
    print('Cookies received: $cookies'); // Log de depuração

    // Verificar se a sessão existe
    Map<String, dynamic>? sessionData =
        sessionId != null ? store.get(sessionId) : null;
    print('Session data retrieved: $sessionData'); // Log de depuração

    if (sessionData == null) {
      // Criar nova sessão
      sessionId = generateSessionId();
      sessionData = {};
      store.set(sessionId, sessionData, options.maxAge);
      res.cookie(options.cookieName, sessionId, {
        'maxAge': options.maxAge,
        'httpOnly': options.httpOnly,
        'secure': options.secure,
        'path': '/',
      });
      print('New session created: $sessionId'); // Log de depuração
    } else {
      // Atualizar o cookie para renovar o tempo de expiração
      res.cookie(options.cookieName, sessionId ?? '', {
        'maxAge': options.maxAge,
        'httpOnly': options.httpOnly,
        'secure': options.secure,
        'path': '/',
      });
      print('Existing session reused: $sessionId'); // Log de depuração
    }

    // Associar a sessão ao objeto Request (usar referência direta)
    req.session = sessionData;
    print('req.session initialized: ${req.session}'); // Log de depuração

    // Processar a requisição
    next();

    // Verificar se é a rota de logout
    if (req.path == '/api/v1/sessions/logout' && req.method == 'POST') {
      if (sessionId != null) {
        store.destroy(sessionId);
        res.clearCookie(options.cookieName, {'path': '/'});
        req.session = {};
        print('Session destroyed: $sessionId'); // Log de depuração
      }
    }
  };
}
