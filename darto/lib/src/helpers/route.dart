import 'package:darto/darto.dart';

/// Returns all routes that matched the current request — including
/// path-based middleware routes and the matched handler route.
///
/// ```dart
/// app.mount('/api/*', (c, next) async { await next(); });
///
/// app.get('/api/users/:id', (c) {
///   final routes = matchedRoutes(c);
///   // e.g. [RouteSpec(ALL /api/*), RouteSpec(GET /api/users/:id)]
///   return c.json({'total': routes.length});
/// });
/// ```
List<RouteSpec> matchedRoutes(Context c) => c.matchedRoutes;

/// Returns the registered route pattern of the matched handler.
///
/// ```dart
/// app.get('/posts/:id', (c) {
///   print(routePath(c)); // '/posts/:id'
///   return c.text('ok');
/// });
/// ```
String? routePath(Context c) => c.routePath;

/// Returns the group prefix **pattern** of the matched route.
///
/// When routes are registered through [Darto.group] or [Router.group], the
/// prefix is preserved as a pattern (param names are not resolved).
///
/// ```dart
/// final api = app.group('/api');
/// api.get('/users/:id', (c) {
///   print(baseRoutePath(c)); // '/api'
///   return c.text('ok');
/// });
///
/// final sub = app.group('/:tenant');
/// sub.get('/data', (c) {
///   print(baseRoutePath(c)); // '/:tenant'
///   return c.text('ok');
/// });
/// ```
String? baseRoutePath(Context c) => c.baseRoutePath;

/// Returns the resolved base path for the current request.
///
/// Unlike [baseRoutePath], dynamic segments in the group prefix are replaced
/// with their actual values from the request URL.
///
/// ```dart
/// final sub = app.group('/:tenant');
/// sub.get('/data', (c) {
///   print(basePath(c)); // e.g. '/acme' for a request to '/acme/data'
///   return c.text('ok');
/// });
/// ```
String? basePath(Context c) => c.basePath;
