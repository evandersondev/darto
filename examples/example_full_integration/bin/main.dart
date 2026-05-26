import 'package:darto/darto.dart';
import 'package:darto/jwt.dart';
import 'package:darto/logger.dart';

const _secret = 'integration-secret-change-in-production';

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

  // Global middleware
  app.use(logger());
  app.onError((err, c) => c.internalError({'error': err.toString()}));
  app.notFound((c) => c.notFound({'error': 'Not found: ${c.req.path}'}));

  // POST /auth/login — returns JWT
  app.route('/auth', (r) {
    r.post('/login', [], (Context c) async {
      final body = await c.req.json();
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
  });

  // Protected API routes
  app.mount('/api', jwt(secret: _secret));

  app.route('/api', (r) {
    // GET /api/profile — returns authenticated user
    r.get('/profile', [], (Context c) => c.ok({'profile': c.user}));

    // POST /api/items — protected + validated body
    r.post('/items', [], (Context c) async {
      final body = await c.req.json();
      return c.created({'item': body, 'createdBy': c.user?['email']});
    });
  });

  app.get('/', [], (Context c) => c.ok({
        'endpoints': [
          'POST /auth/login',
          'GET  /api/profile  [jwt required]',
          'POST /api/items    [jwt required]',
        ]
      }));

  app.listen(3000, () => print('Full integration server running on port 3000'));
}
