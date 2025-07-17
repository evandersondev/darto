import '../darto.dart';

class Layer {
  final String? path;
  final RegExp? regex;
  final List<String> paramNames;
  final String? method;
  final List<dynamic> handlers;
  final Map<String, List<ParamMiddleware>> paramCallbacks;

  Layer({
    this.path,
    this.regex,
    this.paramNames = const [],
    this.method,
    this.handlers = const [],
    this.paramCallbacks = const {},
  });
}
