# darto_auth

Authentication for the [Darto](https://pub.dev/packages/darto) web framework —
**password hashing** (PBKDF2, no native deps) and **session-based auth** guards
built on Darto's session middleware.

## Install

```yaml
dependencies:
  darto_auth: ^1.0.0
```

## Password hashing

PBKDF2-HMAC-SHA256. Hashes are self-describing (`pbkdf2-sha256$<iters>$<salt>$<key>`),
so `verifyPassword` reads the parameters back from the stored string.

```dart
import 'package:darto_auth/darto_auth.dart';

final hash = hashPassword('s3cret');         // store this
final ok   = verifyPassword('s3cret', hash); // true

// Tune the work factor:
const hasher = PasswordHasher(iterations: 200000);
final h = hasher.hash('s3cret');
```

| Symbol | Description |
|---|---|
| `hashPassword(password)` | Hash with the default `PasswordHasher` |
| `verifyPassword(password, hash)` | Verify (constant-time; never throws) |
| `PasswordHasher({iterations, saltLength})` | Configurable hasher (`.hash` / `.verify`) |

## Session auth

Built on `package:darto/session.dart` — register the session middleware once.

```dart
import 'package:darto/darto.dart';
import 'package:darto/session.dart';
import 'package:darto_auth/darto_auth.dart';

app.use(sessionMiddleware(secret: env.sessionSecret));

app.post('/login', [], (c) async {
  final body = await c.req.json();
  final user = await users.findByEmail(body['email']);
  if (user == null || !verifyPassword(body['password'], user.hash)) {
    return c.unauthorized({'error': 'invalid credentials'});
  }
  await signIn(c, {'id': user.id, 'role': user.role});
  return c.ok({'ok': true});
});

app.get('/me', [authGuard()], (c) => c.ok(authUser(c)));
app.post('/logout', [], (c) { signOut(c); return c.noContent(); });
```

| Symbol | Description |
|---|---|
| `signIn(c, user)` | Store the user in the session (authenticate) |
| `signOut(c)` | Clear the session |
| `authUser(c)` | The session user, or `null` |
| `authGuard({onUnauthorized})` | Middleware — `401` (or `onUnauthorized`) when unauthenticated; sets `c.user` otherwise |

## OAuth 2.0 / OpenID Connect

`OAuthProvider` implements the Authorization-Code flow with **PKCE S256** and
a randomised `state` (CSRF protection).  Pre-configured factories for **Google**
(OIDC) and **GitHub** (OAuth2), plus a generic constructor for anything else.

### Google (OIDC, with discovery)

```dart
import 'package:darto/darto.dart';
import 'package:darto/session.dart';
import 'package:darto_auth/darto_auth.dart';

final google = await OAuthProvider.google(
  clientId: env.googleClientId,
  clientSecret: env.googleClientSecret,
  redirectUri: 'http://localhost:3000/auth/google/callback',
);

app.use(sessionMiddleware(secret: env.sessionSecret));

google.attach(app, '/auth/google', onSignIn: (c, user) async {
  await signIn(c, {'id': user.id, 'email': user.email, 'name': user.name});
  return c.redirect('/');
});
```

This registers two routes:

- `GET /auth/google` → redirects to Google's authorize endpoint (with PKCE + state).
- `GET /auth/google/callback` → validates state, exchanges the code, decodes the
  `id_token` claims (OIDC), and invokes `onSignIn(c, user)`.

### GitHub (plain OAuth2)

```dart
final github = OAuthProvider.github(
  clientId: env.githubClientId,
  clientSecret: env.githubClientSecret,
  redirectUri: 'http://localhost:3000/auth/github/callback',
);

github.attach(app, '/auth/github', onSignIn: (c, user) async {
  await signIn(c, {'id': user.id, 'email': user.email});
  return c.redirect('/');
});
```

### Anything else

```dart
final azure = OAuthProvider(
  authorizeUrl: 'https://login.microsoftonline.com/<tenant>/oauth2/v2.0/authorize',
  tokenUrl:     'https://login.microsoftonline.com/<tenant>/oauth2/v2.0/token',
  userInfoUrl:  'https://graph.microsoft.com/oidc/userinfo',
  clientId: env.azureClientId,
  clientSecret: env.azureClientSecret,
  redirectUri: '...',
  scopes: ['openid', 'email', 'profile'],
  isOidc: true,
);
```

| Symbol | Description |
|---|---|
| `OAuthProvider(...)` | Generic OAuth2 provider |
| `OAuthProvider.oidc({issuer, ...})` | OIDC discovery from `/.well-known/openid-configuration` |
| `OAuthProvider.google({...})` | Google sign-in via OIDC |
| `OAuthProvider.github({...})` | GitHub sign-in via OAuth2 |
| `provider.attach(app, prefix, {onSignIn, failureRedirect})` | Register start + callback routes |
| `provider.buildAuthorizeUrl({state, codeChallenge})` | Inspect what redirects look like (tests) |
| `OAuthUser` | Normalised `(id, email, name, picture, raw)` profile |
| `pkceVerifier()` / `pkceChallenge(v)` | PKCE helpers (S256) |
| `randomToken([bytes])` | Hex token — for the OAuth `state` |

> **Note on id_token signature verification.** The `id_token` claims are
> decoded but not verified against the issuer's JWKS — authenticity comes
> from the TLS channel to the token endpoint, which is sufficient for the
> code flow.  JWKS verification is on the roadmap as an opt-in for advanced
> setups (multi-issuer, public clients, etc.).

<br/>

---

<br/>

### Support 💖

If you find Darto Auth useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the package and make it even better!

<br/>
