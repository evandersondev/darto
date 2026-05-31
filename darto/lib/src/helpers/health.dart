import 'dart:async';

import 'package:darto/darto.dart';

/// A single named liveness/readiness check. Return `true` when healthy.
typedef HealthCheck = FutureOr<bool> Function();

/// Builds a health-check [Handler].
///
/// Returns **200** with `{"status": "ok"}` when every check in [checks] passes,
/// or **503** with `{"status": "unavailable", "checks": {...}}` when any fails
/// (a throwing check counts as down). Extra static fields can be added via
/// [info] (e.g. version, uptime).
///
/// ```dart
/// import 'package:darto/health.dart';
///
/// // Liveness — always 200 while the process is up
/// app.get('/healthz', [], health());
///
/// // Readiness — 503 until dependencies are reachable
/// app.get('/readyz', [], health(
///   checks: {'db': () => db.ping(), 'cache': () => redis.ping()},
///   info: () => {'version': '1.0.0'},
/// ));
/// ```
Handler health({
  Map<String, HealthCheck> checks = const {},
  Map<String, dynamic> Function()? info,
}) {
  return (Context c) async {
    final results = <String, String>{};
    var healthy = true;

    for (final entry in checks.entries) {
      bool ok;
      try {
        ok = await entry.value();
      } catch (_) {
        ok = false;
      }
      results[entry.key] = ok ? 'up' : 'down';
      if (!ok) healthy = false;
    }

    final body = <String, dynamic>{
      'status': healthy ? 'ok' : 'unavailable',
      if (checks.isNotEmpty) 'checks': results,
      if (info != null) ...info(),
    };

    return healthy ? c.ok(body) : c.status(503).json(body);
  };
}
