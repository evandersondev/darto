import 'dart:async';

import 'package:darto/darto.dart';

/// State returned by a [RateLimitStore] after recording a request.
class RateLimitHit {
  /// Requests counted in the current window (including this one).
  final int count;

  /// When the current window resets.
  final DateTime resetAt;

  const RateLimitHit(this.count, this.resetAt);
}

/// Backing store for [rateLimit].
///
/// The default is [MemoryRateLimitStore] (process-local). Implement this to
/// back the limiter with a shared store (Redis/Memcached) for horizontally
/// scaled deployments — see the `darto_rate_limit` plugin on the roadmap.
abstract class RateLimitStore {
  /// Records a request for [key] within [window] and returns the new state.
  FutureOr<RateLimitHit> hit(String key, Duration window);

  /// Clears the counter for [key].
  FutureOr<void> reset(String key);
}

/// In-memory, process-local **fixed-window** store (zero dependencies).
///
/// Suitable for single-instance deployments. Expired entries are swept lazily
/// once the map grows past [sweepThreshold] to bound memory.
class MemoryRateLimitStore implements RateLimitStore {
  final Map<String, RateLimitHit> _hits = {};
  final int sweepThreshold;

  MemoryRateLimitStore({this.sweepThreshold = 10000});

  @override
  RateLimitHit hit(String key, Duration window) {
    final now = DateTime.now();
    final existing = _hits[key];
    final RateLimitHit updated;
    if (existing == null || !now.isBefore(existing.resetAt)) {
      updated = RateLimitHit(1, now.add(window)); // new window
    } else {
      updated = RateLimitHit(existing.count + 1, existing.resetAt);
    }
    _hits[key] = updated;
    if (_hits.length > sweepThreshold) {
      _hits.removeWhere((_, h) => now.isAfter(h.resetAt));
    }
    return updated;
  }

  @override
  void reset(String key) => _hits.remove(key);
}

/// Rate-limiting middleware — caps requests per key within a time [window].
///
/// Zero-dependency and in-memory by default ([MemoryRateLimitStore]); pass a
/// custom [store] for a distributed backend. Emits the IETF draft `RateLimit-*`
/// headers and `Retry-After` on rejection (429), and short-circuits the
/// pipeline without running the handler.
///
/// ```dart
/// import 'package:darto/rate_limit.dart';
///
/// // 100 requests / minute per client IP
/// app.use(rateLimit(max: 100, window: Duration(minutes: 1)));
///
/// // Per-user limit with a custom rejection and a skip rule
/// app.mount('/api/*', rateLimit(
///   max: 20,
///   keyGenerator: (c) => c.user?['id'] ?? c.req.ip,
///   skip: (c) => c.req.path == '/api/health',
///   onLimitExceeded: (c) => c.status(429).json({'error': 'slow down'}),
/// ));
/// ```
Middleware rateLimit({
  int max = 60,
  Duration window = const Duration(minutes: 1),
  String Function(Context c)? keyGenerator,
  bool Function(Context c)? skip,
  Handler? onLimitExceeded,
  bool standardHeaders = true,
  RateLimitStore? store,
}) {
  final RateLimitStore backing = store ?? MemoryRateLimitStore();
  final String Function(Context) keyOf =
      keyGenerator ?? (Context c) => c.req.ip;

  return (Context c, Next next) async {
    if (skip != null && skip(c)) {
      await next();
      return;
    }

    final hit = await backing.hit(keyOf(c), window);
    final remaining = (max - hit.count).clamp(0, max);
    final resetIn = hit.resetAt.difference(DateTime.now()).inSeconds;
    final reset = resetIn < 0 ? 0 : resetIn;

    if (standardHeaders) {
      c.header('RateLimit-Limit', '$max');
      c.header('RateLimit-Remaining', '$remaining');
      c.header('RateLimit-Reset', '$reset');
    }

    if (hit.count > max) {
      c.header('Retry-After', '$reset');
      if (onLimitExceeded != null) {
        await onLimitExceeded(c);
      } else {
        c.status(429).json({'error': 'Too Many Requests'});
      }
      return; // short-circuit — handler not run
    }

    await next();
  };
}
