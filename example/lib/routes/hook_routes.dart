import 'package:darto/darto.dart';

void hookRoutes(Darto app) {
  // define not found route handler
  app.addHook.onNotFound((Request req, Response res) {
    res.redirect('/404');
  });

  app.get('/404', (Request req, Response res) {
    res.status(NOT_FOUND).json({'404': 'Route not found (Auto Redirect)'});
  });

  // Define onRequest hook
  app.addHook.onRequest((req) {
    print("onRequest: ${req.method} ${req.path}");
  });

  // Define preHandler hook
  app.addHook.preHandler((req, res) async {
    print("preHandler: processing request before handler");
  });

  // Define onResponse hook
  app.addHook.onResponse((req, res) {
    print("onResponse: response sent for ${req.method} ${req.path}");
  });

  // Define onError hook
  app.addHook.onError((error, req, res) {
    print("onError: error occurred ${error.toString()} on ${req.path}");
  });
}
