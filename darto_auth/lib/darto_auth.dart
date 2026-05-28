/// Authentication for the [Darto](https://pub.dev/packages/darto) web framework.
///
/// - **Password hashing** — PBKDF2-HMAC-SHA256, no native dependencies
///   ([hashPassword] / [verifyPassword] / [PasswordHasher]).
/// - **Session auth** — [signIn] / [signOut] / [authUser] and the [authGuard]
///   middleware, built on Darto's `sessionMiddleware`.
///
/// ```dart
/// import 'package:darto/darto.dart';
/// import 'package:darto/session.dart';
/// import 'package:darto_auth/darto_auth.dart';
///
/// app.use(sessionMiddleware(secret: env.sessionSecret));
///
/// app.post('/login', [], (c) async {
///   final body = await c.req.json();
///   final user = await users.findByEmail(body['email']);
///   if (user == null || !verifyPassword(body['password'], user.hash)) {
///     return c.unauthorized({'error': 'invalid credentials'});
///   }
///   await signIn(c, {'id': user.id});
///   return c.ok({'ok': true});
/// });
///
/// app.get('/me', [authGuard()], (c) => c.ok(authUser(c)));
/// ```
library darto_auth;

export 'src/oauth/oauth_provider.dart'
    show OAuthProvider, OAuthUserMapper, OnOAuthSignIn;
export 'src/oauth/oauth_user.dart' show OAuthUser;
export 'src/oauth/pkce.dart' show pkceVerifier, pkceChallenge, randomToken;
export 'src/password.dart';
export 'src/session_auth.dart';
