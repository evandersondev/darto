import 'package:darto/darto.dart';

Handler loggerTestMiddleware(Request req, Response res, NextFunction next) {
  req.log.access('-----  Request received  ------');
  next();
}
