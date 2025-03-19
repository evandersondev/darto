import 'package:darto/darto.dart';

Router appRouter() {
  final router = Router();

  router.get('/', (req, res) {
    res.send('Dashboard Page');
  });

  router.get('/profile', (req, res) {
    res.send('Profile Page');
  });

  return router;
}
