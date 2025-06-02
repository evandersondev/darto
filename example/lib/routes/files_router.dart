import 'package:darto/darto.dart';

void fileRoutes(Darto app) {
  app.get('/about', (Request req, Response res) {
    res.sendFile('public/about.html');
  });
}
