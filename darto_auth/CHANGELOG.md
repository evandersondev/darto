## 1.1.0

- **OAuth 2.0 / OIDC** — `OAuthProvider` with PKCE S256 on by default,
  randomised `state` (CSRF), Authorization-Code flow exchange and a
  pluggable `userMapper`.
- `OAuthProvider.oidc(issuer: ...)` — async factory that discovers the
  authorization, token and userinfo endpoints from
  `.well-known/openid-configuration`.
- Pre-configured `OAuthProvider.google(...)` (via OIDC) and
  `OAuthProvider.github(...)` factories.
- `provider.attach(app, prefix, onSignIn: ...)` — registers
  `GET <prefix>` (redirect) and `GET <prefix>/callback` (exchange + sign-in)
  in one call.  Integrates directly with the session-based `signIn` helper.
- `id_token` claims decoded (no signature verification — TLS to the token
  endpoint is the source of authenticity; JWKS verification is a future
  optional add-on).
- `OAuthUser`, `pkceVerifier`, `pkceChallenge`, `randomToken` exported.

## 1.0.0

- Initial release.
- **Password hashing** — PBKDF2-HMAC-SHA256 with random salt, no native
  dependencies. `hashPassword` / `verifyPassword` and the configurable
  `PasswordHasher`. Hashes are self-describing and verified in constant time.
- **Session auth** (built on `package:darto/session.dart`): `signIn`, `signOut`,
  `authUser`, and the `authGuard()` middleware (401 / custom handler when
  unauthenticated; sets `c.user` on success).
