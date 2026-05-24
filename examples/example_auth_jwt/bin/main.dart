import 'package:darto/darto.dart';
import 'package:darto/jwt.dart';
import 'package:darto/require_roles.dart';

const _secret = 'super-secret-key-change-in-production';

// Fake user store
final _users = [
  {
    'id': 1,
    'email': 'alice@example.com',
    'password': 'pass123',
    'roles': ['user']
  },
  {
    'id': 2,
    'email': 'admin@example.com',
    'password': 'admin123',
    'roles': ['user', 'admin']
  },
];

void main() {
  final app = Darto();

  app.onError((err, c) => c.internalError({'error': err.toString()}));

  // POST /login — issues a JWT
  app.post('/login', [], (Context c) async {
    final body = await c.body();
    final email = body['email'] as String?;
    final password = body['password'] as String?;

    final user = _users.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => {},
    );

    if (user.isEmpty) return c.unauthorized({'error': 'Invalid credentials'});

    final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
    final token = await sign(
      {'id': user['id'], 'email': user['email'], 'roles': user['roles'], 'exp': exp},
      _secret,
    );

    return c.ok({'token': token});
  });

  // GET /me — requires valid JWT
  app.get('/me', [jwt(secret: _secret)], (Context c) {
    return c.ok({'user': c.user});
  });

  // GET /admin — requires JWT + admin role
  app.get('/admin', [jwt(secret: _secret), requireRoles(['admin'])], (Context c) {
    return c.ok({'message': 'Admin area', 'user': c.user});
  });

  app.listen(3000, () => print('JWT auth server running on port 3000'));
}
