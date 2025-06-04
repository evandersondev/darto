import 'package:darto/darto.dart';

Handler loggerTestMiddleware(Request req, Response res, Next next) {
  req.log.access('Request received');
  next();
}
