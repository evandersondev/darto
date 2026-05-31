/// Distributed [RateLimitStore] backends for Darto.
///
/// Plug the [RedisRateLimitStore] into the core `rateLimit()` middleware so
/// multiple app instances share the same counters:
///
/// ```dart
/// import 'package:darto/rate_limit.dart';
/// import 'package:darto_rate_limit/darto_rate_limit.dart';
///
/// final store = await RedisRateLimitStore.connect(host: env.redisHost);
/// app.use(rateLimit(max: 100, window: Duration(minutes: 1), store: store));
/// ```
library;

export 'src/redis_rate_limit_store.dart' show RedisRateLimitStore;
