import 'dart:io';

import 'package:darto/darto.dart';
import 'package:darto/rate_limit.dart';
import 'package:darto_rate_limit/darto_rate_limit.dart';

void main() async {
  // The core rateLimit() middleware is in-memory by default. Point REDIS_HOST
  // at a Redis server to share the counter across every app instance — the
  // only thing that changes is the store.
  RateLimitStore? store;
  final redisHost = Platform.environment['REDIS_HOST'];
  if (redisHost != null) {
    store = await RedisRateLimitStore.connect(host: redisHost, prefix: 'rl:');
    print('Using RedisRateLimitStore @ $redisHost (shared across instances)');
  } else {
    print('Using the in-memory store (set REDIS_HOST to go distributed)');
  }

  final app = Darto();

  // 5 requests per 10s per client IP. Emits RateLimit-* headers and returns
  // 429 with Retry-After once the window is exhausted.
  app.use(rateLimit(
    max: 5,
    window: const Duration(seconds: 10),
    store: store, // null → the core MemoryRateLimitStore
  ));

  app.get('/', [], (Context c) => c.ok({'ok': true, 'at': DateTime.now().toIso8601String()}));

  await app.listen(3000, () => print('Rate-limit example on http://localhost:3000'));
}
