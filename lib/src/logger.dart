import 'package:darto/src/darto_logger.dart';

class Logger {
  final bool debug;
  final bool info;
  final bool warning;
  final bool error;
  final bool access;

  Logger({
    this.debug = false,
    this.info = false,
    this.warning = false,
    this.error = false,
    this.access = false,
  });

  // create a singleton instance of the logger
  static final Logger _instance = Logger();
  static Logger get instance => _instance;
  static Logger get I => _instance;

  bool isActive(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return debug;
      case LogLevel.info:
        return info;
      case LogLevel.warning:
        return warning;
      case LogLevel.error:
        return error;
      case LogLevel.access:
        return access;
    }
  }
}
