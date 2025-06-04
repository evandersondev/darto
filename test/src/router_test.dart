import 'package:darto/darto.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../__mocks__/http_mock.dart';

void main() {
  late Router router;

  setUp(() {
    router = Router();
    registerFallbackValue(MockRequest());
    registerFallbackValue(MockResponse());
  });

  // TODO: resolve private method
  test('Adiciona rota GET com um RouteHandler', () {
    handler(req, res) {}

    router.get('/hello', handler);

    // expect(router.routes.containsKey('GET'), isTrue);
    // final route = router.routes['GET']!.first;

    // expect(route.key.hasMatch('/hello'), isTrue);
    // expect(route.value['handlers'], contains(handler));
    // expect(route.value['paramNames'], isEmpty);
  });

// TODO: resolve private method
  test('Adiciona rota POST com Middleware e RouteHandler', () {
    middleware(req, res, next) {}
    handler(req, res) {}

    router.post('/post', middleware, handler);

    // final route = router.routes['POST']!.first;
    // expect(route.key.hasMatch('/post'), isTrue);
    // expect(route.value['handlers'], [middleware, handler]);
  });

// TODO: resolve private method
  test('Adiciona rota PUT com Middleware + dois handlers', () {
    middleware(req, res, next) {}
    handler1(req, res) {}
    handler2(req, res) {}

    router.put('/put', middleware, handler1, handler2);

    // final route = router.routes['PUT']!.first;
    // expect(route.value['handlers'], [middleware, handler1, handler2]);
  });

// TODO: resolve private method
  test('Adiciona rota DELETE com path param', () {
    handler1(req, res) {}

    router.delete('/item/:id', handler1);

    // final route = router.routes['DELETE']!.first;
    // expect(route.key.hasMatch('/item/123'), isTrue);
    // expect(route.value['paramNames'], ['id']);
  });

  test('Lança erro se rota não tiver handler', () {
    expect(() => router.get('/fail', null), throwsArgumentError);
  });
}
