import 'package:darto/darto.dart';
import 'package:darto/logger.dart';
import 'package:darto/proxy.dart';

// ── Upstream targets ──────────────────────────────────────────────────────────
//
// This example simulates two upstream services running locally.
// Start them with:
//   dart run bin/upstream_a.dart   (port 4001 — "users" service)
//   dart run bin/upstream_b.dart   (port 4002 — "products" service)
//
// Then start the gateway:
//   dart run bin/server.dart       (port 3000)
//
// Routes:
//   GET  http://localhost:3000/api/users     → proxied to localhost:4001/users
//   GET  http://localhost:3000/api/products  → proxied to localhost:4002/products
//   GET  http://localhost:3000/external      → proxied to httpbin.org (real HTTP)
//   POST http://localhost:3000/api/users     → proxied with body forwarding
//
// ─────────────────────────────────────────────────────────────────────────────

const _usersUpstream    = 'http://localhost:4001';
const _productsUpstream = 'http://localhost:4002';

void main() async {
  final app = Darto();

  app.use(logger());

  // ── Transparent proxy — forward method + headers + body ───────────────────

  // /api/users  and  /api/users/anything  → users service
  Future<Response> userProxy(Context c) {
    final sub = c.req.path.substring('/api/users'.length); // '' | '/1' | '/1/posts'
    return proxy(c, '$_usersUpstream/users$sub');
  }

  app.all('/api/users', [], userProxy);
  app.all('/api/users/*path', [], userProxy);

  // /api/products  and  /api/products/anything  → products service
  Future<Response> productProxy(Context c) {
    final sub = c.req.path.substring('/api/products'.length);
    return proxy(c, '$_productsUpstream/products$sub');
  }

  app.all('/api/products', [], productProxy);
  app.all('/api/products/*path', [], productProxy);

  // ── Proxy with header overrides ───────────────────────────────────────────

  // Inject an internal auth token and strip cookies before forwarding
  app.get('/secure', [], (c) {
    return proxy(
      c,
      '$_usersUpstream/users',
      options: ProxyOptions(
        headers: {
          'Authorization': 'Bearer INTERNAL_SECRET',
          'Cookie': null, // strip cookies — don't forward to upstream
          'X-Forwarded-By': 'darto-gateway',
        },
      ),
    );
  });

  // ── Proxy to external service ─────────────────────────────────────────────

  // GET /external → httpbin.org/get (real external HTTP request)
  app.get('/external', [], (c) {
    return proxy(c, 'https://httpbin.org/get');
  });

  // ── Proxy with method override ────────────────────────────────────────────

  // Always send as GET even if client sent POST
  app.post('/force-get', [], (c) {
    return proxy(
      c,
      '$_usersUpstream/users',
      options: const ProxyOptions(
        method: 'GET',
        forwardBody: false, // no body for GET
      ),
    );
  });

  // ── Health check (gateway itself) ─────────────────────────────────────────
  app.get('/health', [], (c) => c.ok({'status': 'gateway ok'}));

  await app.listen(3000, () => print('Gateway running on http://localhost:3000'));
}
