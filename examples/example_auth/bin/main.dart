import 'package:darto/darto.dart';
import 'package:darto/session.dart';
import 'package:darto_auth/darto_auth.dart';

// A fake user store. Passwords are stored as PBKDF2 hashes, never plaintext.
final _users = <String, Map<String, dynamic>>{};

void main() async {
  // Seed one user: register a hash at boot.
  _users['alice@example.com'] = {
    'id': 1,
    'email': 'alice@example.com',
    'hash': hashPassword('s3cret'),
  };

  final app = Darto();

  // Session middleware backs the auth guard (signed cookie).
  app.use(sessionMiddleware(secret: 'change-me-to-a-32+-char-secret!!!'));

  // Register — hash the password before storing it.
  app.post('/register', [], (Context c) async {
    final body = await c.req.json();
    final email = body['email'] as String;
    _users[email] = {
      'id': _users.length + 1,
      'email': email,
      'hash': hashPassword(body['password'] as String),
    };
    return c.created({'email': email});
  });

  // Login — verify the password (constant-time) and start a session.
  app.post('/login', [], (Context c) async {
    final body = await c.req.json();
    final user = _users[body['email']];
    if (user == null ||
        !verifyPassword(body['password'] as String, user['hash'] as String)) {
      return c.unauthorized({'error': 'invalid credentials'});
    }
    await signIn(c, {'id': user['id'], 'email': user['email']});
    return c.ok({'ok': true});
  });

  // Protected — authGuard() returns 401 when there's no session.
  app.get('/me', [authGuard()], (Context c) => c.ok(authUser(c)));

  app.post('/logout', [], (Context c) {
    signOut(c);
    return c.noContent();
  });

  // ── OAuth 2.0 / OIDC (optional) ──
  // Uncomment and supply real credentials to enable "Sign in with Google".
  // Then open /auth/google in a browser.
  //
  // final google = await OAuthProvider.google(
  //   clientId: 'YOUR_CLIENT_ID',
  //   clientSecret: 'YOUR_CLIENT_SECRET',
  //   redirectUri: 'http://localhost:3000/auth/google/callback',
  // );
  // google.attach(app, '/auth/google', onSignIn: (c, user) async {
  //   await signIn(c, {'id': user.id, 'email': user.email, 'name': user.name});
  //   return c.redirect('/me');
  // });

  await app.listen(3000, () => print('Auth example on http://localhost:3000'));
}
