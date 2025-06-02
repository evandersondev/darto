import 'dart:async';

import 'package:darto/darto.dart';

typedef Next = void Function([Exception error]);
typedef Middleware = dynamic Function(Request req, Response res, Next next);
typedef RouteHandler = dynamic Function(Request req, Response res);
typedef Timeout = void Function(
    Exception err, Request req, Response res, void Function());
typedef Err = Exception;
typedef Handler = void;
typedef DartoRouteBuilder = void Function(Darto app);
typedef RouterRouteBuilder = void Function(Router router);
typedef ParamMiddleware = void Function(
    Request req, Response res, Next next, String value);
typedef RenderLayout = FutureOr<Response> Function(String content);
