import 'package:darto/src/logger.dart';
import 'package:test/test.dart';

void main() {
  final log = Logger();

  group('DartoLogger', () {
    test('log calls logDebug for LogLevel.debug', () {
      expect(() => log.debug('Debug message'), prints(contains('[DEBUG]')));
    });

    test('log calls logInfo for LogLevel.info', () {
      expect(() => log.info('Info message'), prints(contains('[INFO]')));
    });

    test('log calls logWarn for LogLevel.warning', () {
      expect(() => log.warn('Warning message'), prints(contains('[WARN]')));
    });

    test('log calls logError for LogLevel.error', () {
      expect(() => log.error('Error message'), prints(contains('[ERROR]')));
    });

    test('log calls logAccess for LogLevel.access', () {
      expect(() => log.access('Access message'), prints(contains('[ACCESS]')));
    });
  });
}
