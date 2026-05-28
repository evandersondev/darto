import 'package:darto/darto.dart';

import 'container.dart';
import 'provider.dart';

/// Builder callback used by [Feature.routes] — receives a [Router] already
/// prefixed by whatever path was passed to [DartoFeature.install] (or the
/// root router when no prefix is given).  Mirrors the callback shape of
/// `app.route(prefix, builder)`.
typedef FeatureRoutes = void Function(Router r);

/// A self-contained slice of an app: the providers it owns and the routes that
/// use them.  Install one (or many) into a [Darto] with `app.install(feature)`.
///
/// ```dart
/// final userFeature = Feature(
///   providers: [userServiceProvider, userRepoProvider],
///   routes: (r) {
///     r.get('/users', [], listUsers);
///     r.post('/users', [authGuard()], createUser);
///   },
/// );
///
/// app.install('/api', userFeature);
/// ```
class Feature {
  /// Synchronous providers owned by this feature.
  final List<Provider> providers;

  /// Async providers owned by this feature.
  final List<AsyncProvider> asyncProviders;

  /// Registers the feature's routes — runs once at [DartoFeature.install] time.
  final FeatureRoutes routes;

  const Feature({
    this.providers = const [],
    this.asyncProviders = const [],
    required this.routes,
  });
}

/// Wires [Feature]s into a [Darto] app.
extension DartoFeature on Darto {
  /// Registers [feature]'s routes on the app, optionally under a [prefix]
  /// (e.g. `/api`).  Returns `this` for chaining.
  ///
  /// The feature's providers are intended to be registered on the [Di]
  /// container passed to `app.use(container.middleware())` — pass them via
  /// `Di(providers: [...userFeature.providers])` or use [collectProviders]
  /// to gather them from a list of features.
  Darto install(Object prefixOrFeature, [Feature? feature]) {
    final (String? prefix, Feature f) = switch ((prefixOrFeature, feature)) {
      (String p, Feature f) => (p, f),
      (Feature f, null) => (null, f),
      _ => throw ArgumentError(
          'install() expects (Feature) or (String prefix, Feature)'),
    };
    // route('', builder) gives us a root-prefixed Router, so the no-prefix
    // and prefixed forms share one code path.
    route(prefix ?? '', (r) => f.routes(r));
    return this;
  }
}

/// Flattens the providers of every feature in [features] into the two lists
/// expected by [Di].  Convenient at app boot:
///
/// ```dart
/// final (sync, async) = collectProviders([userFeature, billingFeature]);
/// final di = Di(providers: sync, asyncProviders: async);
/// ```
(List<Provider>, List<AsyncProvider>) collectProviders(
    Iterable<Feature> features) {
  final sync = <Provider>[];
  final async = <AsyncProvider>[];
  for (final f in features) {
    sync.addAll(f.providers);
    async.addAll(f.asyncProviders);
  }
  return (sync, async);
}
