import 'package:darto/darto.dart';

Handler routeMiddleware(Request req, Response res, Next next) async {
  print('Request Type: ${req.method}');
  next();
}
