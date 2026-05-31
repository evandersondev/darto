import 'dart:async';

import 'package:darto/darto.dart';
import 'package:test/test.dart';

import '../support/harness.dart';

void main() {
  group('server', () {
    test('binds to a custom host and exposes the bound port', () async {
      final app = Darto();
      app.get('/ping', [], (c) => c.text('pong'));

      final ready = Completer<void>();
      unawaited(app.serve(
        port: 0,
        host: 'localhost',
        shutdownSignals: false,
        onListen: ready.complete,
      ));
      await ready.future;

      expect(app.isRunning, isTrue);
      expect(app.port, isNotNull);
      expect(app.port! > 0, isTrue);

      final res = await request(app.port!, '/ping');
      expect(await bodyOf(res), equals('pong'));

      await app.stop();
      expect(app.isRunning, isFalse);
      expect(app.port, isNull);
    });

    test('stop() drains an in-flight request before closing', () async {
      final app = Darto();
      app.get('/slow', [], (c) async {
        await Future.delayed(const Duration(milliseconds: 300));
        return c.text('done');
      });

      final ready = Completer<void>();
      unawaited(app.serve(
        port: 0,
        shutdownSignals: false,
        onListen: ready.complete,
      ));
      await ready.future;
      final port = app.port!;

      // Fire the slow request without awaiting; let it reach the handler.
      final pending =
          request(port, '/slow', headers: {'connection': 'close'}).then(bodyOf);
      await Future.delayed(const Duration(milliseconds: 50));

      // Stop while in flight — the request must still complete.
      await app.stop(drainTimeout: const Duration(seconds: 2));

      expect(await pending, equals('done'));
      expect(app.isRunning, isFalse);
    });
  });
}
