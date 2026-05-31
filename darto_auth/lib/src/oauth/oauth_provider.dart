import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:darto/darto.dart';
import 'package:darto/session.dart';

import 'oauth_user.dart';
import 'pkce.dart';

/// Called from the OAuth callback handler once the provider has returned a
/// usable user profile.  Typically this stores the user in the session
/// (`signIn`) and redirects somewhere.
typedef OnOAuthSignIn = Future<Response> Function(Context c, OAuthUser user);

/// Maps the raw provider response (token endpoint's `id_token` claims for OIDC,
/// or the `userInfoUrl` body otherwise) into an [OAuthUser].
typedef OAuthUserMapper = OAuthUser Function(Map<String, dynamic> raw);

const _sessionKey = '__darto_oauth';

/// An OAuth 2.0 / OpenID Connect provider description — declared once, then
/// attached to a Darto app on a chosen prefix.
///
/// ```dart
/// final github = OAuthProvider.github(
///   clientId: env.githubClientId,
///   clientSecret: env.githubClientSecret,
///   redirectUri: 'http://localhost:3000/auth/github/callback',
/// );
///
/// app.use(sessionMiddleware(secret: env.sessionSecret));
/// github.attach(app, '/auth/github', onSignIn: (c, user) async {
///   await signIn(c, {'id': user.id, 'email': user.email});
///   return c.redirect('/');
/// });
/// ```
class OAuthProvider {
  final String authorizeUrl;
  final String tokenUrl;
  final String? userInfoUrl;
  final String clientId;
  final String clientSecret;
  final String redirectUri;
  final List<String> scopes;

  /// PKCE S256 on by default — adds the `code_challenge` to the authorize
  /// request and the matching `code_verifier` to the token request.
  final bool usePkce;

  /// `true` when this provider was created via [OAuthProvider.oidc] — enables
  /// `id_token` decoding (claims only; no signature verification).
  final bool isOidc;

  /// Maps the raw provider response into an [OAuthUser].  Defaults to a
  /// permissive mapper that handles OIDC (`sub`, `email`, `name`, `picture`)
  /// and common OAuth2 shapes (`id`, `email`, `name`).
  final OAuthUserMapper userMapper;

  /// Lets tests inject a mock [HttpClient] for the token + userinfo HTTP calls.
  final HttpClient Function() httpClientFactory;

  OAuthProvider({
    required this.authorizeUrl,
    required this.tokenUrl,
    this.userInfoUrl,
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
    required this.scopes,
    this.usePkce = true,
    this.isOidc = false,
    OAuthUserMapper? userMapper,
    HttpClient Function()? httpClientFactory,
  })  : userMapper = userMapper ?? _defaultMapper,
        httpClientFactory = httpClientFactory ?? HttpClient.new;

  /// Discovers an OIDC provider from its issuer URL — fetches
  /// `<issuer>/.well-known/openid-configuration` and uses the
  /// `authorization_endpoint`, `token_endpoint` and `userinfo_endpoint`.
  static Future<OAuthProvider> oidc({
    required String issuer,
    required String clientId,
    required String clientSecret,
    required String redirectUri,
    required List<String> scopes,
    OAuthUserMapper? userMapper,
    HttpClient Function()? httpClientFactory,
  }) async {
    final base = issuer.endsWith('/') ? issuer.substring(0, issuer.length - 1) : issuer;
    final url = Uri.parse('$base/.well-known/openid-configuration');
    final client = (httpClientFactory ?? HttpClient.new)();
    try {
      final req = await client.getUrl(url);
      final res = await req.close();
      if (res.statusCode >= 400) {
        throw StateError('OIDC discovery failed: HTTP ${res.statusCode} for $url');
      }
      final body = await res.transform(utf8.decoder).join();
      final doc = jsonDecode(body) as Map<String, dynamic>;
      return OAuthProvider(
        authorizeUrl: doc['authorization_endpoint'] as String,
        tokenUrl: doc['token_endpoint'] as String,
        userInfoUrl: doc['userinfo_endpoint'] as String?,
        clientId: clientId,
        clientSecret: clientSecret,
        redirectUri: redirectUri,
        scopes: scopes,
        isOidc: true,
        userMapper: userMapper,
        httpClientFactory: httpClientFactory,
      );
    } finally {
      client.close(force: true);
    }
  }

  /// Google sign-in via OIDC (discovery at `https://accounts.google.com`).
  static Future<OAuthProvider> google({
    required String clientId,
    required String clientSecret,
    required String redirectUri,
    List<String> scopes = const ['openid', 'email', 'profile'],
    HttpClient Function()? httpClientFactory,
  }) {
    return oidc(
      issuer: 'https://accounts.google.com',
      clientId: clientId,
      clientSecret: clientSecret,
      redirectUri: redirectUri,
      scopes: scopes,
      httpClientFactory: httpClientFactory,
    );
  }

  /// GitHub sign-in — OAuth2 (no OIDC), userinfo at `/user`.
  static OAuthProvider github({
    required String clientId,
    required String clientSecret,
    required String redirectUri,
    List<String> scopes = const ['read:user', 'user:email'],
    HttpClient Function()? httpClientFactory,
  }) {
    return OAuthProvider(
      authorizeUrl: 'https://github.com/login/oauth/authorize',
      tokenUrl: 'https://github.com/login/oauth/access_token',
      userInfoUrl: 'https://api.github.com/user',
      clientId: clientId,
      clientSecret: clientSecret,
      redirectUri: redirectUri,
      scopes: scopes,
      userMapper: (raw) => OAuthUser(
        id: '${raw['id']}',
        email: raw['email'] as String?,
        name: (raw['name'] as String?) ?? raw['login'] as String?,
        picture: raw['avatar_url'] as String?,
        raw: raw,
      ),
      httpClientFactory: httpClientFactory,
    );
  }

  /// Registers `GET <prefix>` (start) and `GET <prefix>/callback` on [app].
  /// Requires `sessionMiddleware` to be installed — it stores the PKCE
  /// verifier and `state` between the two requests.
  void attach(
    Darto app,
    String prefix, {
    required OnOAuthSignIn onSignIn,
    String? successRedirect,
    String? failureRedirect,
  }) {
    app.get(prefix, [], (c) async => _start(c));
    app.get('$prefix/callback', [], (c) async {
      try {
        final user = await _callback(c);
        return await onSignIn(c, user);
      } catch (e) {
        if (failureRedirect != null) return c.redirect(failureRedirect);
        return c.status(400).json({'error': 'oauth_failed', 'detail': e.toString()});
      }
    });
  }

  /// Public for unit tests — builds the authorize URL the start handler
  /// redirects to.
  Uri buildAuthorizeUrl({
    required String state,
    String? codeChallenge,
  }) {
    final params = <String, String>{
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': scopes.join(' '),
      'state': state,
      if (codeChallenge != null) ...{
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    };
    final base = Uri.parse(authorizeUrl);
    return base.replace(queryParameters: {...base.queryParameters, ...params});
  }

  Future<Response> _start(Context c) async {
    final state = randomToken();
    final verifier = usePkce ? pkceVerifier() : null;
    final challenge = verifier == null ? null : pkceChallenge(verifier);
    sessionContext(c).update({
      _sessionKey: {'state': state, if (verifier != null) 'verifier': verifier},
    });
    final url = buildAuthorizeUrl(state: state, codeChallenge: challenge);
    return c.redirect(url.toString());
  }

  Future<OAuthUser> _callback(Context c) async {
    final code = c.req.query('code');
    final state = c.req.query('state');
    if (code == null) throw StateError('Missing "code"');

    final saved = sessionContext(c).get()?[_sessionKey] as Map?;
    final expectedState = saved?['state'];
    final verifier = saved?['verifier'] as String?;
    if (expectedState == null || expectedState != state) {
      throw StateError('Invalid or missing state — possible CSRF');
    }

    // Wipe the one-shot OAuth params from the session before doing any I/O.
    final all = Map<String, dynamic>.from(sessionContext(c).get() ?? {});
    all.remove(_sessionKey);
    sessionContext(c).update(all);

    final token = await _exchangeToken(code, verifier);
    final raw = isOidc && token['id_token'] is String
        ? _decodeJwtClaims(token['id_token'] as String)
        : await _fetchUserInfo(token['access_token'] as String);
    return userMapper(raw);
  }

  Future<Map<String, dynamic>> _exchangeToken(
      String code, String? verifier) async {
    final client = httpClientFactory();
    try {
      final req = await client.postUrl(Uri.parse(tokenUrl));
      req.headers.contentType =
          ContentType('application', 'x-www-form-urlencoded');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final body = <String, String>{
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'client_secret': clientSecret,
        if (verifier != null) 'code_verifier': verifier,
      };
      req.write(body.entries
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&'));
      final res = await req.close();
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode >= 400) {
        throw StateError('Token endpoint ${res.statusCode}: $text');
      }
      return jsonDecode(text) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _fetchUserInfo(String accessToken) async {
    if (userInfoUrl == null) {
      throw StateError('No userInfoUrl configured and no OIDC id_token to decode');
    }
    final client = httpClientFactory();
    try {
      final req = await client.getUrl(Uri.parse(userInfoUrl!));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final res = await req.close();
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode >= 400) {
        throw StateError('UserInfo ${res.statusCode}: $text');
      }
      return jsonDecode(text) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }
}

OAuthUser _defaultMapper(Map<String, dynamic> raw) {
  final id = (raw['sub'] ?? raw['id'] ?? '').toString();
  return OAuthUser(
    id: id,
    email: raw['email'] as String?,
    name: raw['name'] as String?,
    picture: raw['picture'] as String?,
    raw: raw,
  );
}

/// Decodes a JWT's payload claims **without** signature verification.  Safe
/// here because we just received the `id_token` over TLS from the issuer's
/// token endpoint — authenticity is already established by the channel.
Map<String, dynamic> _decodeJwtClaims(String jwt) {
  final parts = jwt.split('.');
  if (parts.length != 3) throw StateError('Malformed JWT');
  var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
  switch (payload.length % 4) {
    case 1:
      throw StateError('Invalid JWT payload length');
    case 2:
      payload += '==';
      break;
    case 3:
      payload += '=';
      break;
  }
  return jsonDecode(utf8.decode(base64.decode(payload))) as Map<String, dynamic>;
}
