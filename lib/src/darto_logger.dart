import 'package:ansicolor/ansicolor.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  access,
}

final AnsiPen infoPen = AnsiPen()..green();
final AnsiPen warnPen = AnsiPen()..yellow();
final AnsiPen errorPen = AnsiPen()..red();
final AnsiPen debugPen = AnsiPen()..blue();
final AnsiPen accessPen = AnsiPen()..magenta();

class DartoLogger {
  static void log(String message, LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        logDebug(message);
        break;
      case LogLevel.info:
        logInfo(message);
        break;
      case LogLevel.warning:
        logWarn(message);
        break;
      case LogLevel.error:
        logError(message);
        break;
      case LogLevel.access:
        logAccess(message);
        break;
    }
  }
}

void logInfo(String message) {
  print(infoPen('[INFO] ${DateTime.now()} - $message'));
}

void logWarn(String message) {
  print(warnPen('[WARN] ${DateTime.now()} - $message'));
}

void logError(String message) {
  print(errorPen('[ERROR] ${DateTime.now()} - $message'));
}

void logDebug(String message) {
  print(debugPen('[DEBUG] ${DateTime.now()} - $message'));
}

void logAccess(String message) {
  print(accessPen('[ACCESS] ${DateTime.now()} - $message'));
}
