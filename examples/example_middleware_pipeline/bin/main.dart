import 'package:darto/darto.dart';

// Middleware 1: timer — wraps the whole request
Middleware timer() => (Context c, Next next) async {
      final start = DateTime.now();
      print('[timer] before — ${c.req.method} ${c.req.path}');
      await next();
      final ms = DateTime.now().difference(start).inMilliseconds;
      print('[timer] after  — ${ms}ms elapsed');
    };

// Middleware 2: request-id — sets a unique id in context
Middleware requestId() => (Context c, Next next) async {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      c.set('requestId', id);
      print('[requestId] assigned id=$id');
      await next();
    };

// Middleware 3: logger-style — logs method + path
Middleware logRequest() => (Context c, Next next) async {
      print('[logger] ${c.req.method} ${c.req.path}');
      await next();
      print('[logger] response sent');
    };

void main() {
  final app = Darto();

  // Chain all three middlewares on a single route
  app.get(
    '/pipeline',
    [timer(), requestId(), logRequest()],
    (Context c) {
      final id = c.get<String>('requestId');
      return c.ok({'requestId': id, 'message': 'Pipeline complete'});
    },
  );

  app.get('/', [], (Context c) => c.ok({'hint': 'Try GET /pipeline'}));

  app.listen(3000, () => print('Middleware pipeline server running on port 3000'));
}
