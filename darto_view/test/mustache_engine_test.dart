import 'dart:io';

import 'package:darto_view/darto_view.dart';
import 'package:test/test.dart';

void main() {
  late Directory views;

  setUp(() {
    views = Directory.systemTemp.createTempSync('darto_view_test');
  });

  tearDown(() {
    if (views.existsSync()) views.deleteSync(recursive: true);
  });

  void writeTemplate(String name, String source) {
    File('${views.path}/$name.mustache').writeAsStringSync(source);
  }

  test('renders a template with interpolated data', () async {
    writeTemplate('hello', 'Hello, {{name}}!');
    final engine = MustacheEngine(viewsPath: views.path);

    final out = await engine.render('hello', {'name': 'Darto'});

    expect(out, 'Hello, Darto!');
  });

  test('renders sections (lists)', () async {
    writeTemplate('list', '{{#items}}[{{.}}]{{/items}}');
    final engine = MustacheEngine(viewsPath: views.path);

    final out = await engine.render('list', {
      'items': ['a', 'b', 'c'],
    });

    expect(out, '[a][b][c]');
  });

  test('does not HTML-escape values (htmlEscapeValues: false)', () async {
    writeTemplate('raw', '{{html}}');
    final engine = MustacheEngine(viewsPath: views.path);

    final out = await engine.render('raw', {'html': '<b>bold</b>'});

    expect(out, '<b>bold</b>');
  });

  test('throws StateError when the template file is missing', () async {
    final engine = MustacheEngine(viewsPath: views.path);

    expect(
      () => engine.render('nope', {}),
      throwsA(isA<StateError>()),
    );
  });

  test('caches the compiled template across renders', () async {
    writeTemplate('cached', 'v={{v}}');
    final engine = MustacheEngine(viewsPath: views.path);

    final first = await engine.render('cached', {'v': 1});
    expect(first, 'v=1');

    // Mutating the file after first render must NOT change output: the compiled
    // template is cached in memory.
    File('${views.path}/cached.mustache').writeAsStringSync('CHANGED {{v}}');
    final second = await engine.render('cached', {'v': 2});
    expect(second, 'v=2');
  });
}
