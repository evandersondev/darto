import 'package:darto/darto.dart';

Router appRouter() {
  final router = Router();

  router.get('/', (req, res) {
    res.send('Dashboard Page');
  });

  router.get('/profile', (req, res) {
    throw Exception('Error in profile route');
  });

  router.get('/events/:id/attendees', (Request req, Response res) {
    return res.send('Attendees for event ${req.params['id']}');
  });

  router.param('user_id', (req, res, next, userId) {
    print('CALLED ONLY ONCE $userId');
    next();
  });

  router.get('/product/:user_id', (req, res) {
    print('although this matches');
    res.send('Product ${req.params['user_id']}');
  });

  return router;
}
