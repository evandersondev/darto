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

  return router;
}
