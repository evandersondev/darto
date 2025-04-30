import 'package:darto/src/darto_logger.dart';
import 'package:test/test.dart';

void main() {
  group('DartoLogger', () {
    test('log calls logDebug for LogLevel.debug', () {
      expect(() => DartoLogger.log('Debug message', LogLevel.debug),
          prints(contains('[DEBUG]')));
    });

    test('log calls logInfo for LogLevel.info', () {
      expect(() => DartoLogger.log('Info message', LogLevel.info),
          prints(contains('[INFO]')));
    });

    test('log calls logWarn for LogLevel.warning', () {
      expect(() => DartoLogger.log('Warning message', LogLevel.warning),
          prints(contains('[WARN]')));
    });

    test('log calls logError for LogLevel.error', () {
      expect(() => DartoLogger.log('Error message', LogLevel.error),
          prints(contains('[ERROR]')));
    });

    test('log calls logAccess for LogLevel.access', () {
      expect(() => DartoLogger.log('Access message', LogLevel.access),
          prints(contains('[ACCESS]')));
    });

    test('logInfo prints a formatted info message', () {
      expect(() => logInfo('Test info'), prints(contains('[INFO]')));
    });

    test('logWarn prints a formatted warning message', () {
      expect(() => logWarn('Test warning'), prints(contains('[WARN]')));
    });

    test('logError prints a formatted error message', () {
      expect(() => logError('Test error'), prints(contains('[ERROR]')));
    });

    test('logDebug prints a formatted debug message', () {
      expect(() => logDebug('Test debug'), prints(contains('[DEBUG]')));
    });

    test('logAccess prints a formatted access message', () {
      expect(() => logAccess('Test access'), prints(contains('[ACCESS]')));
    });
  });
}
