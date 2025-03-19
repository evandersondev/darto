import 'package:darto/src/types.dart';

/// 📌 **Classe Router**
///
/// Esta classe é responsável por gerenciar as rotas da aplicação.
class Router {
  final Map<String, List<MapEntry<RegExp, Map<String, dynamic>>>> routes = {};

  void get(String path, dynamic first, [dynamic second, dynamic third]) =>
      _addRoute('GET', path, first, second, third);
  void post(String path, dynamic first, [dynamic second, dynamic third]) =>
      _addRoute('POST', path, first, second, third);
  void put(String path, dynamic first, [dynamic second, dynamic third]) =>
      _addRoute('PUT', path, first, second, third);
  void delete(String path, dynamic first, [dynamic second, dynamic third]) =>
      _addRoute('DELETE', path, first, second, third);

  void _addRoute(String method, String path, dynamic first,
      [dynamic second, dynamic third]) {
    final paramNames = <String>[];
    final regexPath = RegExp(
      '^' +
          path.replaceAllMapped(RegExp(r':(\w+)'), (match) {
            paramNames.add(match.group(1)!);
            return '([^/]+)';
          }) +
          r'$',
    );

    final List<dynamic> handlers = [];

    if (first is Middleware || first is RouteHandler) {
      handlers.add(first);
    }
    if (second != null) {
      handlers.add(second);
    }
    if (third != null) {
      handlers.add(third);
    }

    if (handlers.isEmpty) {
      throw ArgumentError("A rota deve ter pelo menos um handler.");
    }

    routes.putIfAbsent(method, () => []).add(
          MapEntry(regexPath, {'handlers': handlers, 'paramNames': paramNames}),
        );
  }
}
