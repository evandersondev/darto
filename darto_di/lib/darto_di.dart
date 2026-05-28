/// Typed dependency injection for Darto.
///
/// ```dart
/// import 'package:darto/darto.dart';
/// import 'package:darto_di/darto_di.dart';
///
/// final envProvider = Provider<Env>((di) => Env.fromFile('.env'));
/// final dbProvider  = Provider<Db>(
///   (di) => Db.connect(di.read(envProvider).dbUrl),
///   onDispose: (db) => db.close(),
/// );
///
/// final di = Di(providers: [envProvider, dbProvider]);
/// await di.warmup();
///
/// final app = Darto()..use(di.middleware());
/// app.get('/health', [], (c) => c.ok({'db': c.read(dbProvider).pingedAt}));
/// ```
library;

export 'src/container.dart' show Di, ContextDi, contextProvider;
export 'src/feature.dart' show Feature, FeatureRoutes, DartoFeature, collectProviders;
export 'src/provider.dart' show Provider, AsyncProvider, Scope, DiRef;
