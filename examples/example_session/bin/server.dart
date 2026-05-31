import 'package:darto/darto.dart';
import 'package:darto/logger.dart';
import 'package:darto/session.dart';

void main() {
  final app = Darto();

  app.use(logger());
  app.use(sessionMiddleware(
    secret: 'super-secret-key-with-at-least-32-chars!!',
    duration: 60 * 1, // 1 minute
  ));

  app.post('/login', [], (c) async {
    final body = await c.req.json();
    final username = body['username'] as String?;

    if (username == null || username.isEmpty) {
      return c.badRequest({'error': 'username required'});
    }

    await sessionContext(c).update({'username': username, 'role': 'user'});
    return c.ok({'message': 'logged in as $username'});
  });

  app.get('/me', [], (c) {
    final data = sessionContext(c).get();
    if (data == null) return c.unauthorized({'error': 'no active session'});
    return c.ok(data);
  });

  app.post('/logout', [], (c) {
    sessionContext(c).delete();
    return c.ok({'message': 'logged out'});
  });

  app.listen(3000, () => print('http://localhost:3000'));
}
