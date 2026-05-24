import 'dart:async';

import 'package:darto/darto.dart';

// ── In-memory cache store ─────────────────────────────────────────────────────

final Map<String, Map<String, _CachedEntry>> _stores = {};

Map<String, _CachedEntry> _openStore(String name) =>
    _stores.putIfAbsent(name, () => {});

class _CachedEntry {
  final Response response;
  final DateTime? expiresAt;

  _CachedEntry(this.response, [this.expiresAt]);

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

int? _parseMaxAge(String? cacheControl) {
  if (cacheControl == null) return null;
  final m =
      RegExp(r'max-age=(\d+)', caseSensitive: false).firstMatch(cacheControl);
  return m != null ? int.tryParse(m.group(1)!) : null;
}

bool _shouldSkipCache(Response r) {
  final cc = (r.extraHeaders['cache-control'] ?? '').toLowerCase();
  if (RegExp(r'(?:^|,\s*)(?:private|no-store|no-cache)').hasMatch(cc)) {
    return true;
  }
  if ((r.extraHeaders['vary'] ?? '').contains('*')) return true;
  if (r.extraHeaders.containsKey('set-cookie')) return true;
  return false;
}

// ── Middleware ────────────────────────────────────────────────────────────────

/// In-memory response cache middleware.
///
/// Caches full responses keyed by URL (or a custom [keyGenerator]). On a cache
/// hit the response is returned immediately without running the handler.
/// Cached entries are automatically invalidated when `max-age` in
/// [cacheControl] expires.
///
/// Responses with `Cache-Control: no-store/no-cache/private`, `Vary: *`, or
/// `Set-Cookie` headers are never cached.
///
/// ```dart
/// // Basic — cache all 200 responses for 1 hour
/// app.get('*', cache(
///   cacheName: 'my-app',
///   cacheControl: 'max-age=3600',
/// ));
///
/// // Cache specific status codes
/// app.get('*', cache(
///   cacheName: 'my-app',
///   cacheControl: 'max-age=3600',
///   cacheableStatusCodes: [200, 404, 412],
/// ));
///
/// // Custom key + lifecycle hooks
/// app.use(cache(
///   cacheName: 'my-app-v1',
///   keyGenerator: (c) => '${c.req.method}:${c.req.path}',
///   onCacheNotAvailable: () =>
///       print('Custom log: Cache API is not available.'),
/// ));
/// ```
Middleware cache({
  required String cacheName,
  bool wait = false, // kept for API compatibility
  String? cacheControl,
  FutureOr<String> Function(Context c)? keyGenerator,
  List<int> cacheableStatusCodes = const [200],
  void Function()? onCacheNotAvailable,
}) {
  final store = _openStore(cacheName);
  final maxAge = _parseMaxAge(cacheControl);

  return (Context c, Next next) async {
    final key = keyGenerator != null
        ? await keyGenerator(c)
        : c.req.url.toString();

    // ── Cache hit ──────────────────────────────────────────────────────────
    final entry = store[key];
    if (entry != null && !entry.isExpired) {
      c.respond(entry.response);
      if (cacheControl != null) c.header('Cache-Control', cacheControl);
      return;
    }

    // Remove stale entry so it doesn't block future caching
    if (entry != null && entry.isExpired) store.remove(key);

    // ── Cache miss ─────────────────────────────────────────────────────────
    await next();

    final response = c.response;
    if (response == null) return;

    if (!cacheableStatusCodes.contains(response.statusCode)) return;
    if (_shouldSkipCache(response)) return;

    if (cacheControl != null) c.header('Cache-Control', cacheControl);

    final expiresAt = maxAge != null
        ? DateTime.now().add(Duration(seconds: maxAge))
        : null;

    store[key] = _CachedEntry(response, expiresAt);
  };
}
