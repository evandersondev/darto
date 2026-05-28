## 1.1.0

- `request(...)` / `get(...)` accept `followRedirects: false` to capture a
  raw 3xx response (its status, headers and `Set-Cookie`) instead of being
  silently followed.  Useful for testing OAuth, post-login redirects, etc.

## 1.0.0

- Initial release.
- `TestClient.create(app)` boots a Darto app on an ephemeral loopback port.
- `get` / `head` / `options` / `post` / `put` / `patch` / `delete` / `request`
  helpers with `json` / `body` / `headers` support.
- `TestResponse` with `statusCode`, `body`, `json`, `header()`, `headers`,
  `cookie()` / `cookies`, and `isOk`.
