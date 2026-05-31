import 'package:darto/darto.dart';
import 'package:darto/session.dart';

/// Session-based authentication helpers, built on Darto's `sessionMiddleware`
/// (`package:darto/session.dart`). Register the session middleware once:
///
/// ```dart
/// import 'package:darto/session.dart';
/// import 'package:darto_auth/darto_auth.dart';
///
/// app.use(sessionMiddleware(secret: env.sessionSecret));
///
/// app.post('/login', [], (c) async {
///   final body = await c.req.json();
///   final user = await users.findByEmail(body['email']);
///   if (user == null || !verifyPassword(body['password'], user.passwordHash)) {
///     return c.unauthorized({'error': 'invalid credentials'});
///   }
///   await signIn(c, {'id': user.id, 'role': user.role});
///   return c.ok({'ok': true});
/// });
///
/// app.get('/me', [authGuard()], (c) => c.ok(authUser(c)));
/// app.post('/logout', [], (c) { signOut(c); return c.noContent(); });
/// ```

/// Stores [user] in the session, marking the request authenticated.
Future<void> signIn(Context c, Map<String, dynamic> user) =>
    sessionContext(c).update(user);

/// Clears the session.
void signOut(Context c) => sessionContext(c).delete();

/// The authenticated user stored in the session, or `null`.
Map<String, dynamic>? authUser(Context c) => sessionContext(c).get();

/// Middleware that requires an authenticated session.
///
/// When there is no session user it short-circuits with `401` (or runs
/// [onUnauthorized] if given). On success it sets `c.user` so handlers and
/// downstream middleware can read it.
Middleware authGuard({Handler? onUnauthorized}) {
  return (Context c, Next next) async {
    final user = sessionContext(c).get();
    if (user == null) {
      if (onUnauthorized != null) {
        await onUnauthorized(c);
      } else {
        c.unauthorized({'error': 'Unauthorized'});
      }
      return;
    }
    c.user = user;
    await next();
  };
}
