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

  test('Adiciona rota GET com um RouteHandler', () {
    final handler = (req, res) {};

    router.get('/hello', handler);

    expect(router.routes.containsKey('GET'), isTrue);
    final route = router.routes['GET']!.first;

    expect(route.key.hasMatch('/hello'), isTrue);
    expect(route.value['handlers'], contains(handler));
    expect(route.value['paramNames'], isEmpty);
  });

  test('Adiciona rota POST com Middleware e RouteHandler', () {
    final middleware = (req, res, next) {};
    final handler = (req, res) {};

    router.post('/post', middleware, handler);

    final route = router.routes['POST']!.first;
    expect(route.key.hasMatch('/post'), isTrue);
    expect(route.value['handlers'], [middleware, handler]);
  });

  test('Adiciona rota PUT com Middleware + dois handlers', () {
    final middleware = (req, res, next) {};
    final handler1 = (req, res) {};
    final handler2 = (req, res) {};

    router.put('/put', middleware, handler1, handler2);

    final route = router.routes['PUT']!.first;
    expect(route.value['handlers'], [middleware, handler1, handler2]);
  });

  test('Adiciona rota DELETE com path param', () {
    final handler1 = (req, res) {};

    router.delete('/item/:id', handler1);

    final route = router.routes['DELETE']!.first;
    expect(route.key.hasMatch('/item/123'), isTrue);
    expect(route.value['paramNames'], ['id']);
  });

  test('Lança erro se rota não tiver handler', () {
    expect(() => router.get('/fail', null), throwsArgumentError);
  });
}
