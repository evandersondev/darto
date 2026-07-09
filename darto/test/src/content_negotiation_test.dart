import 'dart:convert';

import 'package:test/test.dart';

import '../support/harness.dart';

void main() {
  group('c.req.accepts', () {
    test('picks the client-preferred type by q-value', () async {
      await withServer((app) {
        app.get('/n', [], (c) {
          final best = c.req.accepts(['application/json', 'text/html']);
          return c.text(best ?? 'none');
        });
      }, (port) async {
        final res = await request(port, '/n',
            headers: {'accept': 'text/html;q=0.9, application/json;q=0.2'});
        expect(await bodyOf(res), equals('text/html'));
      });
    });

    test('falls back to server order when Accept is absent', () async {
      await withServer((app) {
        app.get('/n', [], (c) {
          final best = c.req.accepts(['application/json', 'text/html']);
          return c.text(best ?? 'none');
        });
      }, (port) async {
        final res = await request(port, '/n');
        expect(await bodyOf(res), equals('application/json'));
      });
    });

    test('honors wildcards (text/*) and returns matching subtype', () async {
      await withServer((app) {
        app.get('/n', [], (c) {
          final best = c.req.accepts(['application/json', 'text/html']);
          return c.text(best ?? 'none');
        });
      }, (port) async {
        final res = await request(port, '/n', headers: {'accept': 'text/*'});
        expect(await bodyOf(res), equals('text/html'));
      });
    });

    test('returns null when nothing is acceptable', () async {
      await withServer((app) {
        app.get('/n', [], (c) {
          final best = c.req.accepts(['application/json']);
          return c.text(best ?? 'none');
        });
      }, (port) async {
        final res =
            await request(port, '/n', headers: {'accept': 'image/png'});
        expect(await bodyOf(res), equals('none'));
      });
    });

    test('treats q=0 as an explicit rejection', () async {
      await withServer((app) {
        app.get('/n', [], (c) {
          final best = c.req.accepts(['application/json', 'text/html']);
          return c.text(best ?? 'none');
        });
      }, (port) async {
        final res = await request(port, '/n', headers: {
          'accept': 'application/json;q=0, text/html;q=0.5',
        });
        expect(await bodyOf(res), equals('text/html'));
      });
    });
  });

  group('c.negotiate', () {
    test('serializes JSON when the client prefers JSON', () async {
      await withServer((app) {
        app.get('/u', [], (c) => c.negotiate({'name': 'Ada'}));
      }, (port) async {
        final res = await request(port, '/u',
            headers: {'accept': 'application/json'});
        expect(res.statusCode, equals(200));
        expect(res.headers.contentType?.mimeType, equals('application/json'));
        final body = jsonDecode(await bodyOf(res)) as Map<String, dynamic>;
        expect(body['name'], equals('Ada'));
      });
    });

    test('serializes plain text when the client prefers text/plain', () async {
      await withServer((app) {
        app.get('/u', [], (c) => c.negotiate({'name': 'Ada'}));
      }, (port) async {
        final res =
            await request(port, '/u', headers: {'accept': 'text/plain'});
        expect(res.statusCode, equals(200));
        expect(res.headers.contentType?.mimeType, equals('text/plain'));
        expect(await bodyOf(res), contains('name'));
      });
    });

    test('uses a custom producer for text/html', () async {
      await withServer((app) {
        app.get('/u', [], (c) {
          return c.negotiate({'name': 'Ada'}, producers: {
            'text/html': (d) =>
                c.html('<b>${(d as Map)['name']}</b>'),
          });
        });
      }, (port) async {
        final res =
            await request(port, '/u', headers: {'accept': 'text/html'});
        expect(res.headers.contentType?.mimeType, equals('text/html'));
        expect(await bodyOf(res), equals('<b>Ada</b>'));
      });
    });

    test('responds 406 when nothing is acceptable', () async {
      await withServer((app) {
        app.get('/u', [], (c) => c.negotiate({'name': 'Ada'}));
      }, (port) async {
        final res =
            await request(port, '/u', headers: {'accept': 'image/png'});
        expect(res.statusCode, equals(406));
      });
    });
  });
}
