/// Structured logging for the [Darto](https://pub.dev/packages/darto) web
/// framework — JSON or pretty output, levels, bound fields and a request-logging
/// middleware with request-id correlation.
///
/// ```dart
/// import 'package:darto/darto.dart';
/// import 'package:darto/request_id.dart';
/// import 'package:darto_logger/darto_logger.dart';
///
/// final log = Logger(minLevel: LogLevel.debug);
///
/// final app = Darto();
/// app.use(requestId());        // adds X-Request-Id
/// app.use(requestLogger(log)); // logs each request with that id
///
/// app.get('/', [], (c) => c.ok({'ok': true}));
/// ```
library darto_logger;

export 'src/logger.dart';
export 'src/request_logger.dart';
