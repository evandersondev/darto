// Upstream A — "users" service on port 4001
import 'package:darto/darto.dart';
import 'package:darto/logger.dart';

void main() async {
  final app = Darto();
  app.use(logger());

  final users = <Map<String, dynamic>>[
    {'id': '1', 'name': 'Alice', 'role': 'admin'},
    {'id': '2', 'name': 'Bob', 'role': 'user'},
  ];

  app.get('/api/users', [], (c) => c.ok(users));

  app.get('/api/users/:id', [], (c) {
    final id = c.req.param('id');
    final user = users.firstWhere(
      (u) => u['id'] == id,
      orElse: () => {},
    );
    return user.isEmpty ? c.notFound({'error': 'User not found'}) : c.ok(user);
  });

  app.post('/api/users', [], (c) async {
    final body = await c.req.json();
    final newUser = <String, dynamic>{...body, 'id': '${users.length + 1}'};
    users.add(newUser);
    return c.created(newUser);
  });

  await app.listen(4001, () => print('Upstream A (users) on http://localhost:4001'));
}
