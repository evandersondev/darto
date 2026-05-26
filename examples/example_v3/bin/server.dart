import 'package:darto/darto.dart';

void main() {
  final app = Darto();

  // global middleware
  app.use((c, next) async {
    final t = Stopwatch()..start();
    await next();
    print('[${c.req.method}] ${c.req.path} — ${t.elapsedMilliseconds}ms');
  });

  // route group
  app.route('/users', (r) {
    r.get('/', [], (c) => c.ok([]));
    r.get('/:id', [], (c) async {
      final id = c.req.paramInt('id');
      if (id == null) return c.badRequest({'error': 'invalid id'});
      return c.ok({'id': id});
    });
    r.post('/', [], (c) async {
      final body = await c.req.json();
      return c.created(body);
    });
  });

  app.get('/health', [], (c) => c.ok({'status': 'ok'}));

  app.onError((err, c) => c.internalError({'error': err.toString()}));
  app.notFound((c) => c.notFound({'error': 'Not Found', 'path': c.req.path}));

  app.listen(3000, () => print('Running on :3000'));
}
