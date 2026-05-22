import 'package:darto/darto.dart';

import 'template_engine.dart';

/// Registers [engine] as the view renderer for every handler downstream.
///
/// After this middleware runs, handlers can call `c.render('template', data)`
/// where the first argument is the template name and the second is the data map.
///
/// ```dart
/// import 'package:darto/darto.dart';
/// import 'package:darto_view/darto_view.dart';
///
/// void main() {
///   final app = Darto();
///
///   app.use(viewEngine(MustacheEngine(viewsPath: 'views')));
///
///   app.get('/', (c) => c.render('index', {'title': 'Home'}));
///
///   app.listen(3000);
/// }
/// ```
Middleware viewEngine(TemplateEngine engine) {
  return (Context c, Next next) async {
    c.setRender((templateName, data) async {
      final html = await engine.render(templateName, data);
      return c.html(html);
    });
    await next();
  };
}
