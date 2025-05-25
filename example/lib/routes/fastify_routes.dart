import 'package:darto/darto.dart';

void fastifyRoutesWithDarto(Darto app) {
  app.get('/fastify', (req, res) {
    res.send('Fastify with Darto');
  });
}

void fastifyRoutesWithRouter(Router router) {
  router.get('/fastify2', (req, res) {
    res.send('Fastify with Router');
  });
}
