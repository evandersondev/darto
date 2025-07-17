import 'dart:io';

import 'package:darto/darto.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpResponse extends Mock implements HttpResponse {}

class MockHttpHeaders extends Mock implements HttpHeaders {}

class MockRequest extends Mock implements Request {}

class MockResponse extends Mock implements Response {}

class MockNext extends Mock {
  void call([dynamic error]);
}

class MockMiddleware extends Mock {
  dynamic call(Request req, Response res, NextFunction next);
}

class MockRouteHandler extends Mock {
  dynamic call(Request req, Response res);
}
