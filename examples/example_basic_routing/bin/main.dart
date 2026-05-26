import 'package:darto/darto.dart';

void main() {
  final app = Darto();

  // GET /
  app.get('/', [], (Context c) => c.ok({'message': 'Welcome to Darto v2!'}));

  // GET /users/:id — route parameter
  app.get('/users/:id', [], (Context c) {
    final id = c.req.paramInt('id');

    if (id == null) return c.badRequest({'error': 'Invalid id'});

    return c.ok({'userId': id, 'name': 'User $id'});
  });

  // GET /search?q=...&page=... — query strings
  app.get('/search', [], (Context c) {
    final q = c.req.query('q') ?? '';
    final page = c.req.queryInt('page') ?? 1;

    return c.ok({'query': q, 'page': page, 'results': []});
  });

  // POST /users — request body
  app.post('/users', [], (Context c) async {
    final body = await c.req.json();
    final name = body['name'] as String?;

    if (name == null || name.isEmpty) {
      return c.badRequest({'error': 'name is required'});
    }

    return c.created({'id': 42, 'name': name});
  });

  app.listen(3000, () => print('Basic routing server running on port 3000'));
}
