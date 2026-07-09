import 'dart:io';

import 'package:darto/darto.dart';
import 'package:darto_test/darto_test.dart';
import 'package:darto_view/darto_view.dart';
import 'package:test/test.dart';

/// A minimal in-memory engine so the middleware can be tested without touching
/// the filesystem. Records the last render call for assertions.
class FakeEngine implements TemplateEngine {
  String? lastTemplate;
  Map<String, dynamic>? lastData;
  final bool shouldThrow;

  FakeEngine({this.shouldThrow = false});

  @override
  Future<String> render(String template, Map<String, dynamic> data) async {
    lastTemplate = template;
    lastData = data;
    if (shouldThrow) throw StateError('boom in engine');
    return '<h1>${data['title']}</h1>';
  }
}

void main() {
  group('viewEngine middleware', () {
    test('wires c.render() to the engine and returns text/html', () async {
      final engine = FakeEngine();
      final app = Darto()..use(viewEngine(engine));
      app.get('/', [], (c) => c.render('index', {'title': 'Home'}));

      final client = await TestClient.create(app);
      addTearDown(client.close);

      final res = await client.get('/');

      expect(res.statusCode, 200);
      expect(res.header('content-type'), contains('text/html'));
      expect(res.body, '<h1>Home</h1>');
      // The middleware forwarded the template name and data verbatim.
      expect(engine.lastTemplate, 'index');
      expect(engine.lastData, {'title': 'Home'});
    });

    test('render works with the real MustacheEngine end-to-end', () async {
      final views =
          Directory.systemTemp.createTempSync('darto_view_mw_test');
      addTearDown(() {
        if (views.existsSync()) views.deleteSync(recursive: true);
      });
      File('${views.path}/greet.mustache')
          .writeAsStringSync('Hi {{name}}!');

      final app = Darto()
        ..use(viewEngine(MustacheEngine(viewsPath: views.path)));
      app.get('/greet', [], (c) => c.render('greet', {'name': 'Ada'}));

      final client = await TestClient.create(app);
      addTearDown(client.close);

      final res = await client.get('/greet');
      expect(res.statusCode, 200);
      expect(res.body, 'Hi Ada!');
    });

    test('an engine error surfaces as a 500 (handled by the framework)',
        () async {
      final app = Darto()..use(viewEngine(FakeEngine(shouldThrow: true)));
      app.get('/', [], (c) => c.render('index', {'title': 'x'}));

      final client = await TestClient.create(app);
      addTearDown(client.close);

      final res = await client.get('/');
      expect(res.statusCode, 500);
    });

    test('without viewEngine, c.render falls back to raw HTML', () async {
      // Context.render() with no registered layout returns the content as-is.
      final app = Darto();
      app.get('/', [], (c) => c.render('<p>raw</p>'));

      final client = await TestClient.create(app);
      addTearDown(client.close);

      final res = await client.get('/');
      expect(res.statusCode, 200);
      expect(res.header('content-type'), contains('text/html'));
      expect(res.body, '<p>raw</p>');
    });
  });
}
