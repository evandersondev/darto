import 'package:darto/darto.dart';

Router authRouter() {
  final router = Router();

  router.get('/', (req, res) {
    res.send('Login Page');
  });

  router.get('/resgiter', (req, res) {
    res.send('Register Page');
  });

  return router;
}
