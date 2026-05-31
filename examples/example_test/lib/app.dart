import 'package:darto/darto.dart';

/// Builds and returns the app without starting it — importable by tests.
Darto buildApp() {
  final db = <int, Map<String, dynamic>>{};
  var nextId = 1;

  final app = Darto();

  // Middleware: add a custom header to every response.
  app.use((c, next) async {
    c.header('X-Powered-By', 'Darto');
    await next();
  });

  app.get('/users', [], (Context c) {
    return c.ok(db.values.toList());
  });

  app.post('/users', [], (Context c) async {
    final body = await c.req.json();
    final user = {'id': nextId, 'name': body['name']};
    db[nextId++] = user;
    return c.created(user);
  });

  app.get('/users/:id', [], (Context c) {
    final id = c.req.paramInt('id');
    final user = db[id];
    if (user == null) return c.notFound({'error': 'not found'});
    return c.ok(user);
  });

  app.put('/users/:id', [], (Context c) async {
    final id = c.req.paramInt('id');
    if (!db.containsKey(id)) return c.notFound({'error': 'not found'});
    final body = await c.req.json();
    db[id!] = {'id': id, 'name': body['name']};
    return c.ok(db[id]!);
  });

  app.delete('/users/:id', [], (Context c) {
    final id = c.req.paramInt('id');
    db.remove(id);
    return c.noContent();
  });

  return app;
}
