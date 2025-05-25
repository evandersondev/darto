import 'package:darto/darto.dart';

typedef Next = void Function();
typedef Middleware = dynamic Function(Request req, Response res, Next next);
typedef RouteHandler = dynamic Function(Request req, Response res);
typedef Timeout = void Function(
    Exception err, Request req, Response res, void Function());
typedef Err = Exception;
typedef Hanlder = void;
typedef NotFoundHandler = void Function(Request req, Response res);
typedef DartoRouteBuilder = void Function(Darto app);
typedef RouterRouteBuilder = void Function(Router router);
