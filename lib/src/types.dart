import 'package:darto/darto.dart';

typedef Next = void Function();
typedef Middleware = void Function(Request req, Response res, Next next);
typedef RouteHandler = void Function(Request req, Response res);
