import 'package:darto/darto.dart';
import 'package:darto/logger.dart';
import 'package:darto/proxy.dart';

// Upstream services (start them before running this gateway):
//   dart run bin/upstream_a.dart   → users service on :4001
//   dart run bin/upstream_b.dart   → products service on :4002
//
// Then:
//   dart run bin/server.dart       → gateway on :3000

const _users = 'http://localhost:4001';
const _products = 'http://localhost:4002';

void main() async {
  final app = Darto();

  app.use(logger());

  // Forward /api/users and /api/users/... → users service
  app.all('/api/users/*', [], (Context c) => proxy(c, '$_users${c.req.path}'));

  // Forward /api/products and /api/products/... → products service
  app.all('/api/products/*', [],
      (Context c) => proxy(c, '$_products${c.req.path}'));

  // Forward with header overrides — inject auth token, tag the proxy
  app.all(
      '/v1/*',
      [],
      (Context c) => proxy(c, 'https://example.com${c.req.path}',
          options: ProxyOptions(
            headers: {
              'X-Proxy-By': 'darto-gateway',
              'Authorization': 'Bearer INTERNAL_SECRET',
              'Cookie': null, // strip cookies before forwarding
            },
          )));

  // Gateway health check
  app.get('/health', [], (c) => c.ok({'status': 'ok'}));

  await app.listen(3000, () => print('Gateway → http://localhost:3000'));
}
