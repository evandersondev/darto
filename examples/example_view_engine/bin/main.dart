import 'package:darto/darto.dart';
import 'package:darto_view/darto_view.dart';

void main() {
  final app = Darto();

  // Register the Mustache engine globally — all handlers can call c.render().
  app.use(viewEngine(MustacheEngine(viewsPath: 'views')));

  app.get('/', [], (Context c) => c.render('index', {
        'title': 'Welcome',
        'message': 'Hello from Darto v2!',
        'items': [
          {'name': 'Routing'},
          {'name': 'Middleware'},
          {'name': 'Validation'},
        ],
      }));

  app.get('/about', [], (Context c) => c.render('about', {
        'title': 'About',
        'description': 'A lightweight Dart web framework.',
        'version': '2.0.0',
      }));

  app.listen(3000, () => print('View engine server running on port 3000'));
}
