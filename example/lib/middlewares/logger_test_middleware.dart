import 'package:darto/darto.dart';

Hanlder loggerTestMiddleware(Request req, Response res, Next next) {
  req.log.access('Request received');
  next();
}
