import 'dart:io';

import 'package:darto_env/darto_env.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('darto_env_test');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  // Writes a .env file and loads it. Keys are prefixed DARTO_ENV_TEST_ so they
  // don't collide with the real process environment (which always wins).
  void writeEnv(String contents) {
    final f = File('${tmp.path}/.env')..writeAsStringSync(contents);
    DartoEnv.load(f.path);
  }

  test('parses simple key=value pairs', () {
    writeEnv('DARTO_ENV_TEST_NAME=darto\n');
    expect(DartoEnv.get('DARTO_ENV_TEST_NAME'), 'darto');
  });

  test('strips surrounding quotes (double and single)', () {
    writeEnv('DARTO_ENV_TEST_D="quoted"\nDARTO_ENV_TEST_S=\'single\'\n');
    expect(DartoEnv.get('DARTO_ENV_TEST_D'), 'quoted');
    expect(DartoEnv.get('DARTO_ENV_TEST_S'), 'single');
  });

  test('ignores blank lines and comments', () {
    writeEnv('# a comment\n\nDARTO_ENV_TEST_OK=1\n   # indented comment\n');
    expect(DartoEnv.get('DARTO_ENV_TEST_OK'), '1');
  });

  test('keeps "=" appearing in the value', () {
    writeEnv('DARTO_ENV_TEST_URL=key=a&b=c\n');
    expect(DartoEnv.get('DARTO_ENV_TEST_URL'), 'key=a&b=c');
  });

  test('missing file is a silent no-op', () {
    expect(() => DartoEnv.load('${tmp.path}/does-not-exist.env'),
        returnsNormally);
  });

  group('typed getters', () {
    test('getInt parses and falls back to default', () {
      writeEnv('DARTO_ENV_TEST_PORT=8080\n');
      expect(DartoEnv.getInt('DARTO_ENV_TEST_PORT'), 8080);
      expect(DartoEnv.getInt('DARTO_ENV_TEST_MISSING', 3000), 3000);
    });

    test('getInt throws FormatException on non-int', () {
      writeEnv('DARTO_ENV_TEST_BAD=abc\n');
      expect(() => DartoEnv.getInt('DARTO_ENV_TEST_BAD'),
          throwsA(isA<FormatException>()));
    });

    test('getDouble parses', () {
      writeEnv('DARTO_ENV_TEST_RATE=1.5\n');
      expect(DartoEnv.getDouble('DARTO_ENV_TEST_RATE'), 1.5);
    });

    test('getBool recognizes truthy tokens (case-insensitive)', () {
      writeEnv('DARTO_ENV_TEST_T1=true\n'
          'DARTO_ENV_TEST_T2=1\n'
          'DARTO_ENV_TEST_T3=YES\n'
          'DARTO_ENV_TEST_T4=on\n'
          'DARTO_ENV_TEST_F1=false\n'
          'DARTO_ENV_TEST_F2=nope\n');
      for (final k in ['T1', 'T2', 'T3', 'T4']) {
        expect(DartoEnv.getBool('DARTO_ENV_TEST_$k'), isTrue, reason: k);
      }
      expect(DartoEnv.getBool('DARTO_ENV_TEST_F1'), isFalse);
      expect(DartoEnv.getBool('DARTO_ENV_TEST_F2'), isFalse);
      expect(DartoEnv.getBool('DARTO_ENV_TEST_ABSENT', true), isTrue);
    });
  });

  group('lookup helpers', () {
    test('get throws StateError when absent and no default', () {
      expect(() => DartoEnv.get('DARTO_ENV_TEST_NEVER_SET'),
          throwsA(isA<StateError>()));
    });

    test('get returns default when absent', () {
      expect(DartoEnv.get('DARTO_ENV_TEST_NEVER_SET', 'fallback'), 'fallback');
    });

    test('maybeGet returns null when absent (never throws)', () {
      expect(DartoEnv.maybeGet('DARTO_ENV_TEST_NEVER_SET'), isNull);
    });
  });
}
