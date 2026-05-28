import 'package:darto_cache/darto_cache.dart';
import 'package:test/test.dart';

void main() {
  group('MemoryCache', () {
    test('get returns null for an absent key', () async {
      final cache = MemoryCache();
      expect(await cache.get('missing'), isNull);
    });

    test('set then get returns the same value', () async {
      final cache = MemoryCache();
      await cache.set('k', 42);
      expect(await cache.get<int>('k'), 42);
    });

    test('set overwrites a previous value', () async {
      final cache = MemoryCache();
      await cache.set('k', 1);
      await cache.set('k', 2);
      expect(await cache.get<int>('k'), 2);
    });

    test('has reports presence without affecting recency', () async {
      final cache = MemoryCache(maxEntries: 2);
      await cache.set('a', 1);
      await cache.set('b', 2);
      expect(await cache.has('a'), true);
      // Adding 'c' should evict 'a' (still LRU because has() didn't promote it)
      await cache.set('c', 3);
      expect(await cache.has('a'), false);
      expect(await cache.has('b'), true);
      expect(await cache.has('c'), true);
    });

    test('delete returns true once and false on the second call', () async {
      final cache = MemoryCache();
      await cache.set('k', 1);
      expect(await cache.delete('k'), true);
      expect(await cache.delete('k'), false);
    });

    test('clear empties every entry', () async {
      final cache = MemoryCache();
      await cache.set('a', 1);
      await cache.set('b', 2);
      await cache.clear();
      expect(await cache.get('a'), isNull);
      expect(await cache.get('b'), isNull);
    });

    test('values past their TTL read back as null', () async {
      final cache = MemoryCache();
      await cache.set('k', 'v', ttl: const Duration(milliseconds: 30));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(await cache.get('k'), isNull);
      expect(await cache.has('k'), false);
    });

    test('values within their TTL are still readable', () async {
      final cache = MemoryCache();
      await cache.set('k', 'v', ttl: const Duration(seconds: 1));
      expect(await cache.get('k'), 'v');
    });

    test('LRU evicts the least-recently-used key on overflow', () async {
      final cache = MemoryCache(maxEntries: 2);
      await cache.set('a', 1);
      await cache.set('b', 2);
      // Touch 'a' — now 'b' is the LRU
      await cache.get('a');
      await cache.set('c', 3); // evicts 'b'
      expect(await cache.get('a'), 1);
      expect(await cache.get('b'), isNull);
      expect(await cache.get('c'), 3);
    });

    test('Map and List values round-trip', () async {
      final cache = MemoryCache();
      await cache.set('user', {'id': 1, 'tags': ['a', 'b']});
      expect(
        await cache.get<Map<String, dynamic>>('user'),
        {'id': 1, 'tags': ['a', 'b']},
      );
    });

    test('remember calls the builder on miss and caches the result', () async {
      var built = 0;
      final cache = MemoryCache();
      Future<int> build() async {
        built++;
        return 99;
      }

      expect(await cache.remember<int>('n', builder: build), 99);
      expect(await cache.remember<int>('n', builder: build), 99);
      expect(built, 1);
    });

    test('remember does not cache a null result', () async {
      var built = 0;
      final cache = MemoryCache();
      Future<int?> build() async {
        built++;
        return null;
      }

      expect(await cache.remember<int>('n', builder: build), isNull);
      expect(await cache.remember<int>('n', builder: build), isNull);
      expect(built, 2);
    });

    test('remember respects ttl on the cached entry', () async {
      var built = 0;
      final cache = MemoryCache();
      Future<int> build() async {
        built++;
        return 7;
      }

      await cache.remember<int>('n',
          ttl: const Duration(milliseconds: 30), builder: build);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await cache.remember<int>('n', builder: build);
      expect(built, 2);
    });
  });
}
