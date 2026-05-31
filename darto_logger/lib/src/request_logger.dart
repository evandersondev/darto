import 'package:darto/darto.dart';

import 'logger.dart';

/// Middleware that logs one structured entry per request: method, path, status
/// and duration. When the request-id middleware ran (`package:darto/request_id.dart`),
/// the id is bound to the line via [Logger.child].
///
/// ```dart
/// import 'package:darto/request_id.dart';
/// import 'package:darto_logger/darto_logger.dart';
///
/// final log = Logger();
/// app.use(requestId());
/// app.use(requestLogger(log));
/// ```
Middleware requestLogger(Logger logger) {
  return (Context c, Next next) async {
    final sw = Stopwatch()..start();
    await next();
    sw.stop();

    final rid = c.get<String?>('requestId');
    final line = (rid != null && rid.isNotEmpty)
        ? logger.child({'requestId': rid})
        : logger;

    line.info('request', {
      'method': c.req.method,
      'path': c.req.path,
      'status': c.response?.statusCode ?? c.statusCode,
      'durationMs': sw.elapsedMilliseconds,
    });
  };
}
