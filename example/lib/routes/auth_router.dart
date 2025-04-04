import 'package:darto/darto.dart';
import 'package:zard/zard.dart';

Router authRouter() {
  final router = Router();

  router.get('/', (req, res) {
    res.send('Login Page');
  });

  router.post('/resgiter', (Request req, Response res) async {
    final schema = z.map({
      'username': z.string().min(3).max(20),
      'password': z.string().min(8).max(20),
    });
    final data = await schema.parseAsync(req.body);

    return res.json(data);
  });

  return router;
}
