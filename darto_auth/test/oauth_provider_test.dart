import 'dart:async';
import 'dart:convert';

import 'package:darto/darto.dart';
import 'package:darto/session.dart';
import 'package:darto_auth/darto_auth.dart';
import 'package:darto_test/darto_test.dart';
import 'package:test/test.dart';

/// Spins up a tiny Darto app that *pretends* to be an OAuth/OIDC provider.
/// Records the form-encoded body received at `/token` so tests can assert on
/// the exact request the OAuthProvider sent.
Future<({
  Darto app,
  TestClient client,
  String baseUrl,
  Map<String, List<String>> Function() lastTokenForm,
})> _startFakeIdp({
  String? idTokenJson,
  Map<String, dynamic>? userInfo,
}) async {
  Map<String, List<String>> lastForm = {};
  final app = Darto();

  app.get('/authorize', [], (c) {
    // A real authorize endpoint redirects the browser back with ?code&state.
    // We don't exercise that here — the test drives the callback directly.
    return c.ok({'ok': true});
  });

  app.post('/token', [], (c) async {
    final raw = await c.req.text();
    lastForm = Uri.splitQueryString(raw).map(
        (k, v) => MapEntry(k, v.split(','))); // for assertion convenience
    return c.json({
      'access_token': 'access_xyz',
      'token_type': 'bearer',
      if (idTokenJson != null)
        'id_token': _fakeJwt(jsonDecode(idTokenJson) as Map<String, dynamic>),
    });
  });

  if (userInfo != null) {
    app.get('/userinfo', [], (c) => c.json(userInfo));
  }

  final client = await TestClient.create(app);
  return (
    app: app,
    client: client,
    baseUrl: 'http://127.0.0.1:${client.port}',
    lastTokenForm: () => lastForm,
  );
}

String _fakeJwt(Map<String, dynamic> claims) {
  String b64(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${b64({"alg": "none"})}.${b64(claims)}.';
}

void main() {
  group('PKCE', () {
    test('verifier has 64 chars by default and is url-safe', () {
      final v = pkceVerifier();
      expect(v.length, 64);
      expect(RegExp(r'^[A-Za-z0-9_\-]+$').hasMatch(v), true);
    });

    test('challenge is deterministic for the same verifier', () {
      const v = 'fixed-verifier-for-test-do-not-reuse-fixed-verifier-for-test';
      final a = pkceChallenge(v);
      final b = pkceChallenge(v);
      expect(a, b);
      expect(a.length, 43); // SHA-256 → 32 bytes → 43 base64url chars
    });

    test('randomToken is 64 hex chars by default', () {
      expect(randomToken().length, 64);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(randomToken()), true);
    });
  });

  group('OAuthProvider.buildAuthorizeUrl', () {
    test('includes every required param + scopes joined by space', () {
      final p = OAuthProvider(
        authorizeUrl: 'https://idp.example.com/auth',
        tokenUrl: 'https://idp.example.com/token',
        clientId: 'cid',
        clientSecret: 'secret',
        redirectUri: 'http://localhost:3000/cb',
        scopes: ['openid', 'email', 'profile'],
      );
      final url = p.buildAuthorizeUrl(state: 'abc', codeChallenge: 'chal');
      final q = url.queryParameters;
      expect(q['client_id'], 'cid');
      expect(q['redirect_uri'], 'http://localhost:3000/cb');
      expect(q['response_type'], 'code');
      expect(q['scope'], 'openid email profile');
      expect(q['state'], 'abc');
      expect(q['code_challenge'], 'chal');
      expect(q['code_challenge_method'], 'S256');
    });
  });

  group('OAuthProvider end-to-end against a fake IdP', () {
    test('OAuth2 flow exchanges code, fetches userinfo, signs the user in',
        () async {
      final idp = await _startFakeIdp(
        userInfo: {
          'id': 42,
          'login': 'eva',
          'name': 'Eva Tester',
          'email': 'eva@example.com',
          'avatar_url': 'https://avatars/eva.png',
        },
      );
      addTearDown(() async => idp.client.close());

      final provider = OAuthProvider.github(
        clientId: 'cid',
        clientSecret: 'secret',
        redirectUri: 'http://localhost:0/auth/github/callback',
      );
      // Repoint at the fake IdP — copy with the test URLs.
      final p = OAuthProvider(
        authorizeUrl: '${idp.baseUrl}/authorize',
        tokenUrl: '${idp.baseUrl}/token',
        userInfoUrl: '${idp.baseUrl}/userinfo',
        clientId: provider.clientId,
        clientSecret: provider.clientSecret,
        redirectUri: provider.redirectUri,
        scopes: provider.scopes,
        userMapper: provider.userMapper,
      );

      final app = Darto()
        ..use(sessionMiddleware(secret: 's3cret-test-key-32chars-aaaaaaaa'));
      OAuthUser? captured;
      p.attach(app, '/auth/github', onSignIn: (c, user) async {
        captured = user;
        await signIn(c, {'id': user.id, 'email': user.email});
        return c.text('ok ${user.id}');
      });

      final client = await TestClient.create(app);
      addTearDown(() async => client.close());

      // 1) Start: hit /auth/github, capture the redirect + the session cookie
      //    (which carries the PKCE verifier + state we'll need for the callback).
      final startRes = await client.get('/auth/github', followRedirects: false);
      expect(startRes.statusCode, 302);
      final authorizeLoc = startRes.headers['location']!;
      final state = Uri.parse(authorizeLoc).queryParameters['state'];
      final cookie = startRes.headers['set-cookie']!.split(';').first;

      // 2) Callback: simulate the IdP redirecting back with ?code=&state=.
      final cbRes = await client.get(
        '/auth/github/callback?code=THE_CODE&state=$state',
        headers: {'cookie': cookie},
      );
      expect(cbRes.statusCode, 200);
      expect(cbRes.body, 'ok 42');
      expect(captured?.email, 'eva@example.com');
      expect(captured?.name, 'Eva Tester');
      expect(captured?.picture, 'https://avatars/eva.png');

      // The token request used PKCE + the right grant_type.
      final form = idp.lastTokenForm();
      expect(form['grant_type']?.first, 'authorization_code');
      expect(form['code']?.first, 'THE_CODE');
      expect(form['client_id']?.first, 'cid');
      expect(form['client_secret']?.first, 'secret');
      expect(form['code_verifier']?.first, isNotNull);
    });

    test('callback with a mismatched state is rejected', () async {
      final idp = await _startFakeIdp(userInfo: {'id': 1});
      addTearDown(() async => idp.client.close());

      final p = OAuthProvider(
        authorizeUrl: '${idp.baseUrl}/authorize',
        tokenUrl: '${idp.baseUrl}/token',
        userInfoUrl: '${idp.baseUrl}/userinfo',
        clientId: 'cid',
        clientSecret: 'secret',
        redirectUri: 'http://localhost:0/cb',
        scopes: ['x'],
      );

      final app = Darto()
        ..use(sessionMiddleware(secret: 's3cret-test-key-32chars-aaaaaaaa'));
      p.attach(app, '/auth/x', onSignIn: (c, _) async => c.text('should not run'));

      final client = await TestClient.create(app);
      addTearDown(() async => client.close());

      final startRes = await client.get('/auth/x', followRedirects: false);
      final cookie = startRes.headers['set-cookie']!.split(';').first;

      final cbRes = await client.get(
        '/auth/x/callback?code=c&state=WRONG_STATE',
        headers: {'cookie': cookie},
      );
      expect(cbRes.statusCode, 400);
      expect(cbRes.body, contains('oauth_failed'));
    });

    test('OIDC flow decodes id_token claims into the user', () async {
      final idp = await _startFakeIdp(
        idTokenJson: jsonEncode({
          'sub': 'goog-123',
          'email': 'eva@example.com',
          'name': 'Eva',
          'picture': 'https://goog/eva.png',
        }),
      );
      addTearDown(() async => idp.client.close());

      final p = OAuthProvider(
        authorizeUrl: '${idp.baseUrl}/authorize',
        tokenUrl: '${idp.baseUrl}/token',
        userInfoUrl: '${idp.baseUrl}/userinfo',
        clientId: 'cid',
        clientSecret: 'secret',
        redirectUri: 'http://localhost:0/cb',
        scopes: ['openid', 'email', 'profile'],
        isOidc: true,
      );

      final app = Darto()
        ..use(sessionMiddleware(secret: 's3cret-test-key-32chars-aaaaaaaa'));
      OAuthUser? captured;
      p.attach(app, '/auth/g', onSignIn: (c, user) async {
        captured = user;
        return c.text('ok');
      });

      final client = await TestClient.create(app);
      addTearDown(() async => client.close());

      final startRes = await client.get('/auth/g', followRedirects: false);
      final state = Uri.parse(startRes.headers['location']!).queryParameters['state'];
      final cookie = startRes.headers['set-cookie']!.split(';').first;

      final cbRes = await client.get(
        '/auth/g/callback?code=c&state=$state',
        headers: {'cookie': cookie},
      );
      expect(cbRes.statusCode, 200);
      expect(captured?.id, 'goog-123');
      expect(captured?.email, 'eva@example.com');
      expect(captured?.picture, 'https://goog/eva.png');
    });
  });
}
