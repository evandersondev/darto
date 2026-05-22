import 'dart:io';

import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as p;

import 'template_engine.dart';

/// Mustache template engine for Darto.
///
/// Templates are looked up at `<viewsPath>/<name>.mustache`.
/// Compiled templates are cached in memory after the first render.
///
/// ```dart
/// app.use(viewEngine(MustacheEngine(viewsPath: 'views')));
///
/// app.get('/', (c) => c.render('index', {'title': 'Home', 'items': [...]}));
/// ```
class MustacheEngine implements TemplateEngine {
  final String viewsPath;

  final Map<String, Template> _cache = {};

  MustacheEngine({this.viewsPath = 'views'});

  @override
  Future<String> render(String template, Map<String, dynamic> data) async {
    final tmpl = _cache[template] ?? await _load(template);
    return tmpl.renderString(data);
  }

  Future<Template> _load(String name) async {
    final filePath = p.join(viewsPath, '$name.mustache');
    final file = File(filePath);

    if (!await file.exists()) {
      throw StateError('Template not found: $filePath');
    }

    final source = await file.readAsString();
    final compiled = Template(source, name: name, htmlEscapeValues: false);
    _cache[name] = compiled;
    return compiled;
  }
}
