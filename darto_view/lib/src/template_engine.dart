/// Abstract interface for Darto view template engines.
///
/// Implement this to plug any template system into [viewEngine].
///
/// ```dart
/// class MyEngine implements TemplateEngine {
///   @override
///   Future<String> render(String template, Map<String, dynamic> data) async {
///     // load and interpolate template file, return HTML string
///   }
/// }
/// ```
abstract class TemplateEngine {
  /// Renders [template] (a template name, without extension) with [data]
  /// and returns the resulting HTML string.
  Future<String> render(String template, Map<String, dynamic> data);
}
