import 'package:darto/darto.dart';
import 'package:darto_cache/darto_cache.dart';

void main() async {
  // In-process cache with LRU + TTL. For multiple instances, swap for:
  //   final cache = await RedisCache.connect(host: 'localhost', prefix: 'app:');
  final Cache cache = MemoryCache(maxEntries: 1000);

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
