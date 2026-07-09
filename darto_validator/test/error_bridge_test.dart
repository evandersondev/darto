import 'dart:convert';

import 'package:darto_validator/darto_validator.dart'; // errorBridge + z
import 'package:test/test.dart';

import 'support/harness.dart';

/// A stand-in for a dartonic-style ORM error, matched by errorBridge purely by
/// its runtime type name (darto has no dependency on any ORM).
class UniqueViolationError implements Exception {
  final String message;
  UniqueViolationError(this.message);
  @override
  String toString() => 'UniqueViolationError: $message';
}

/// A domain error handled only by a custom mapper.
class TeapotError implements Exception {}

void main() {
  group('errorBridge', () {
    test('maps a thrown ZardError to 422 with an issues list', () async {
      await withServer((app) {
        app.use(errorBridge());
        app.get('/z', [], (c) {
          final schema = z.map({'name': z.string().min(3)});
          // parse throws ZardError on invalid input
          schema.parse({'name': 'ab'});
          return c.ok();
        });
      }, (port) async {
        final res = await request(port, '/z');
        final body = jsonDecode(await bodyOf(res)) as Map<String, dynamic>;

        expect(res.statusCode, equals(422));
        expect(body['issues'], isA<List>());
        expect((body['issues'] as List), isNotEmpty);
        final first = (body['issues'] as List).first as Map;
        expect(first.containsKey('message'), isTrue);
        expect(first.containsKey('type'), isTrue);
        expect(first.containsKey('path'), isTrue);
      });
    });

    test('a custom mapper wins over the defaults and the 500 fallback',
        () async {
      await withServer((app) {
        app.use(errorBridge(mappers: [
          (error, c) {
            if (error is TeapotError) {
              return c.status(418).json({'error': "I'm a teapot"});
            }
            return null; // fall through
          },
        ]));
        app.get('/teapot', [], (c) => throw TeapotError());
      }, (port) async {
        final res = await request(port, '/teapot');
        final body = jsonDecode(await bodyOf(res)) as Map<String, dynamic>;

        expect(res.statusCode, equals(418));
        expect(body['error'], equals("I'm a teapot"));
      });
    });

    test('duck-types an ORM UniqueViolationError to 409', () async {
      await withServer((app) {
        app.use(errorBridge());
        app.get('/dup', [], (c) => throw UniqueViolationError('email taken'));
      }, (port) async {
        final res = await request(port, '/dup');
        expect(res.statusCode, equals(409));
      });
    });

    test('unknown errors fall through to a 500', () async {
      await withServer((app) {
        app.use(errorBridge());
        app.get('/boom', [], (c) => throw StateError('kaboom'));
      }, (port) async {
        final res = await request(port, '/boom');
        expect(res.statusCode, equals(500));
      });
    });

    test('unknown errors delegate to app.onError when set', () async {
      await withServer((app) {
        app.onError((err, c) => c.status(500).json({'handled': true}));
        app.use(errorBridge());
        app.get('/boom', [], (c) => throw StateError('kaboom'));
      }, (port) async {
        final res = await request(port, '/boom');
        final body = jsonDecode(await bodyOf(res)) as Map<String, dynamic>;
        expect(res.statusCode, equals(500));
        expect(body['handled'], isTrue);
      });
    });
  });
}
