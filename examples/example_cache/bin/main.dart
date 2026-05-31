import 'dart:io';

import 'package:darto/darto.dart';
import 'package:darto_cache/darto_cache.dart';

void main() async {
  // Set REDIS_HOST=localhost to use RedisCache (run `docker compose up -d` first).
  // Without it, falls back to in-process MemoryCache.
  final redisHost = Platform.environment['REDIS_HOST'];
  final Cache cache = redisHost != null
      ? await RedisCache.connect(host: redisHost, prefix: 'app:')
      : MemoryCache(maxEntries: 1000);

  print('Cache backend: ${redisHost != null ? 'Redis @ $redisHost' : 'MemoryCache'}');

  // Pretend this is a slow database lookup.
  Future<Map<String, dynamic>> fetchUser(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return {'id': id, 'name': 'User $id', 'fetchedAt': DateTime.now().toIso8601String()};
  }

  final app = Darto();

  // remember(): returns the cached value on a hit; on a miss it runs the
  // builder, stores the result with the TTL, and returns it. Hit the same id
  // twice within 10s — the second response is instant and identical.
  app.get('/users/:id', [], (Context c) async {
    final id = c.req.paramInt('id') ?? 0;
    final user = await cache.remember<Map<String, dynamic>>(
      'user:$id',
      ttl: const Duration(seconds: 10),
      builder: () => fetchUser(id),
    );
    return c.ok(user);
  });

  // Manual get/set/delete.
  app.delete('/users/:id', [], (Context c) async {
    await cache.delete('user:${c.req.param('id')}');
    return c.noContent();
  });

  await app.listen(3000, () => print('Cache example on http://localhost:3000'));
}
