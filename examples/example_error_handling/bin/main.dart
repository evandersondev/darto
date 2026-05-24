import 'package:darto/darto.dart';

// Middleware that throws before calling next()
Middleware throwingMiddleware() => (Context c, Next next) async {
      throw Exception('Error thrown inside middleware');
    };

void main() {
  final app = Darto();

  // Global error handler
  app.onError(
    (err, c) => c.internalError({'error': err.toString()}),
  );

  // Custom 404 handler
  app.notFound((c) => c.notFound({'error': 'Route not found: ${c.req.path}'}));

  // GET /ok — happy path
  app.get('/ok', [], (Context c) => c.ok({'status': 'all good'}));

  // GET /throw-handler — throws inside the handler
  app.get('/throw-handler', [], (Context c) {
    throw Exception('Oops! Something went wrong in the handler');
  });

  // GET /throw-middleware — throws inside middleware
  app.get(
    '/throw-middleware',
    [throwingMiddleware()],
    (Context c) => c.ok({'should': 'never reach here'}),
  );

  app.listen(3000, () => print('Error handling server running on port 3000'));
}
