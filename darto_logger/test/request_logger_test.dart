import 'dart:convert';

import 'package:darto/darto.dart';
import 'package:darto/request_id.dart';
import 'package:darto_logger/darto_logger.dart';
import 'package:darto_test/darto_test.dart';
import 'package:test/test.dart';

void main() {
  group('requestLogger', () {
    test('logs method, path, status, duration and the request id', () async {
      final lines = <String>[];
      final log = Logger(output: lines.add);

      final app = Darto();
      app.use(requestId());
      app.use(requestLogger(log));
      app.get('/ping', [], (c) => c.ok({'pong': true}));

      final client = await TestClient.create(app);
      final res = await client.get('/ping');
      expect(res.statusCode, 200);
      await client.close();

      expect(lines, isNotEmpty);
      final entry = jsonDecode(lines.last) as Map<String, dynamic>;
      expect(entry['msg'], equals('request'));
      expect(entry['method'], equals('GET'));
      expect(entry['path'], equals('/ping'));
      expect(entry['status'], equals(200));
      expect(entry['durationMs'], isA<int>());
      expect(entry['requestId'], isA<String>());
    });
  });
}
