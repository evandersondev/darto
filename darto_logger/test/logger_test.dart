import 'dart:convert';

import 'package:darto_logger/darto_logger.dart';
import 'package:test/test.dart';

void main() {
  group('Logger', () {
    test('emits a JSON line with ts, level, msg and fields', () {
      final lines = <String>[];
      final log = Logger(output: lines.add);

      log.info('hello', {'port': 3000});

      expect(lines, hasLength(1));
      final entry = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(entry['level'], equals('info'));
      expect(entry['msg'], equals('hello'));
      expect(entry['port'], equals(3000));
      expect(entry['ts'], isA<String>());
    });

    test('drops entries below minLevel', () {
      final lines = <String>[];
      final log = Logger(minLevel: LogLevel.warn, output: lines.add);

      log.debug('nope');
      log.info('nope');
      log.warn('yes');
      log.error('also yes');

      expect(lines, hasLength(2));
    });

    test('child binds fields onto every line', () {
      final lines = <String>[];
      final log = Logger(output: lines.add).child({'requestId': 'abc'});

      log.info('one');
      log.info('two');

      for (final l in lines) {
        expect((jsonDecode(l) as Map)['requestId'], equals('abc'));
      }
    });

    test('error includes error and stackTrace', () {
      final lines = <String>[];
      final log = Logger(output: lines.add);

      log.error('boom', error: StateError('x'), stackTrace: StackTrace.current);

      final entry = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(entry['error'], contains('x'));
      expect(entry['stackTrace'], isA<String>());
    });

    test('pretty mode is not JSON', () {
      final lines = <String>[];
      final log = Logger(pretty: true, output: lines.add);

      log.info('hi', {'k': 'v'});

      expect(lines.single, contains('INFO'));
      expect(lines.single, contains('hi'));
      expect(lines.single, contains('k=v'));
    });
  });
}
