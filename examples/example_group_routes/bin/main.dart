import 'package:darto/darto.dart';

void main() {
  final app = Darto();

  // app.route() — inline grouping
  app.route('/api/v1', (r) {
    r.get('/users', [], (Context c) => c.ok({'version': 'v1', 'users': []}));

    r.get('/users/:id', [],
        (Context c) => c.ok({'version': 'v1', 'id': c.req.param('id')}));

    r.post('/users', [], (Context c) async {
      final body = await c.req.json();
      return c.created({'version': 'v1', 'created': body});
    });
  });

  // app.route() — v2 group
  app.route('/api/v2', (r) {
    r.get('/users', [], (Context c) => c.ok({
          'version': 'v2',
          'users': [],
          'meta': {'total': 0}
        }));

    r.get('/users/:id', [],
        (Context c) => c.ok({'version': 'v2', 'id': c.req.paramInt('id')}));

    r.post('/users', [], (Context c) async {
      final body = await c.req.json();
      return c.created({
        'version': 'v2',
        'created': body,
        'timestamp': DateTime.now().toIso8601String()
      });
    });
  });

  // app.group() — alternative style
  final admin = app.group('/admin');

  admin.get('/dashboard', [],
      (Context c) => c.ok({'section': 'admin', 'page': 'dashboard'}));
  admin.get('/users', [],
      (Context c) => c.ok({'section': 'admin', 'users': []}));

  app.get('/', [], (Context c) => c.ok({
        'routes': [
          'GET /api/v1/users',
          'GET /api/v1/users/:id',
          'POST /api/v1/users',
          'GET /api/v2/users',
          'GET /api/v2/users/:id',
          'POST /api/v2/users',
          'GET /admin/dashboard',
          'GET /admin/users',
        ]
      }));

  app.listen(3000, () => print('Group routes server running on port 3000'));
}
