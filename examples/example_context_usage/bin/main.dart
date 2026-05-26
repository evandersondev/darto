import 'package:darto/darto.dart';

// Middleware: inject a request-id into context via c.set
Middleware injectRequestId() => (Context c, Next next) async {
      c.set('requestId', 'req-${DateTime.now().millisecondsSinceEpoch}');
      await next();
    };

void main() {
  final app = Darto();

  // c.set / c.get
  app.get('/context', [injectRequestId()], (Context c) {
    final id = c.get<String>('requestId');
    return c.ok({'requestId': id});
  });

  // c.param / c.paramInt
  app.get('/users/:id', [], (Context c) {
    return c.ok({
      'paramString': c.req.param('id'),
      'paramInt': c.req.paramInt('id'),
    });
  });

  // c.query / c.queryInt
  app.get('/search', [], (Context c) {
    return c.ok({
      'q': c.req.query('q'),
      'page': c.req.queryInt('page') ?? 1,
    });
  });

  // c.req.json
  app.post('/echo', [], (Context c) async {
    final body = await c.req.json();
    return c.ok({'received': body});
  });

  // c.header
  app.get('/whoami', [], (Context c) {
    return c.ok({
      'userAgent': c.req.header('user-agent'),
      'method': c.req.method,
      'path': c.req.path,
      'ip': c.req.ip,
    });
  });

  app.listen(3000, () => print('Context usage server running on port 3000'));
}
