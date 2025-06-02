import 'package:darto/darto.dart';

void renderRoutes(Darto app) {
  // Config template layout
  app.use((Request req, Response res, Next next) {
    res.setRender((content) {
      return res.html('''
        <html>
          <head>
            <title>My layout</title>
          </head>
          <body>
            <h1>My Template Layout</h1>
            $content
            <footer>
            <p>This is the footer</p>
            </footer>
          </body>
        </html>
        ''');
    });

    next();
  });

  app.get('/', (Request req, Response res) {
    res.render('index', {
      'title': 'Welcome',
      'header': 'Hello',
      'message': 'This is a sample mustache template rendered with Darto.',
    });
  });
}
