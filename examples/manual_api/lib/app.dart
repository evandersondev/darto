import 'package:darto/bearer_auth.dart';
import 'package:darto/darto.dart';
import 'package:darto/dev.dart';
import 'package:darto/jwt.dart';
import 'package:darto/logger.dart';
import 'package:darto_env/darto_env.dart';
import 'package:manual_api/logger.dart';
import 'package:manual_api/modules/users/user_routes.dart';

Darto createApp() {
  DartoEnv.load();

  final app = Darto();

  app.use(logger());

  app.route('/users', userRoutes);

  app.get('/products/:id/users/:userId/orders/:orderId', [], (c) {
    log("Test", ['My logger']);
    return c.ok({
      'id': c.req.param('id'),
      'userId': c.req.param('userId'),
      'orderId': c.req.param('orderId'),
    });
  });

  final admin = app.group("admin");

  admin.get("/dash", [], (c) {
    return c.text("Deu certo");
  });

  // 🔹 Return image (opens in browser)
  app.get('/image', [], (c) async {
    return await c.file('assets/image.png');
  });

  // 🔹 Retorn Pdf (opens in browser)
  app.get('/pdf', [], (c) async {
    return await c.file('assets/file.pdf');
  });

  // 🔹 Force download
  app.get('/download', [], (c) async {
    return await c.download('assets/file.pdf', filename: 'meu-arquivo.pdf');
  });

  // 🔹 Simples file text
  app.get('/text', [], (c) async {
    return await c.file('assets/test.txt');
  });

  // Context: render, setRender, error, env
  // Request: parseBody

  // app.mount('/auth/*', basicAuth(username: 'user', password: 'pass'));

  // app.mount('/auth/*', basicAuth(
  //   username: 'user',
  //   password: 'pass',
  //   onAuthSuccess: (c, username) {
  //     print('Basic auth success for $username');
  //     c.set('username', username);
  //   },
  //   realm: 'My realm',
  // ));

  // app.mount('/auth/*', basicAuth(
  //   verifyUser: (username, password, c) {
  //     return username == 'user' && password == 'pass';
  //   },
  // ));

  // app.mount('/api/*', bearerAuth(token: 'token'));

  app.mount(
    '/api/*',
    bearerAuth(
      verifyToken: (token, c) {
        return token == 'token';
      },
    ),
  );

  app.get('/api/v1/users', [], (c) {
    return c.json({
      'users': ['user1', 'user2'],
    });
  });

  app.mount('/auth/*', jwt(secret: 'secret', alg: 'HS256'));

  app.get('/auth/page', [], (Context c) {
    final payload = c.get('jwtPayload');
    return c.json(payload);
  });

  // app.mount('/auth/*', (Context c, Next next) {
  //   final jwtMiddleware = jwt(secret: '', alg: 'HS256');
  //   return jwtMiddleware(c, next);
  // });

  app
      .route('/hello')
      .get([], (c) => c.text('GET'))
      .post([], (c) => c.text('POST'))
      .put([], (c) => c.text('PUT'))
      .delete([], (c) => c.noContent());

  app.onError((err, c) {
    return c.json({'error': err.toString()}, 500);
  });

  showRoutes(app, verbose: true);

  app.use((Context c, Next next) async {
    c.setRender(
      (content, props) => c.html('''
      <!DOCTYPE html>
      <html>
        <head><title>${props['title'] ?? 'Darto'}</title></head>
        <body>$content</body>
      </html>
    '''),
    );
    await next();
  });

  app.get('/about', [], (Context c) {
    return c.render('<p>About us</p>', {'title': 'About'});
  });

  return app;
}
