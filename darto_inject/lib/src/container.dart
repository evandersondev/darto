import 'dart:async';

import 'package:darto/darto.dart';

import 'provider.dart';

/// State-bag key under which the per-request scope is stored on the [Context].
const _diScopeKey = '__darto_inject_scope';

/// Built-in [Provider] that yields the current request's [Context].  Only
/// readable from a **request-scoped** factory — otherwise there is no Context
/// to bind to.
///
/// Use it to write providers that depend on something off the request:
///
/// ```dart
/// final currentUserProvider = AsyncProvider<User?>(
///   (di) async {
///     final c = di.read(contextProvider);
///     return userService.fromHeader(c.req.header('authorization'));
///   },
///   scope: Scope.request,
/// );
/// ```
final contextProvider = Provider<Context>(
  (_) => throw StateError(
      'contextProvider can only be read inside a request scope'),
  scope: Scope.request,
  name: 'contextProvider',
);

/// Holds factories, per-scope caches and disposers.
///
/// Build it once at app boot, attach it with `app.use(container.middleware())`,
/// and `await container.dispose()` on shutdown to run app-scope `onDispose`
/// callbacks.
class Di implements DiRef {
  /// Builds a container that knows about [providers] and [asyncProviders].
  /// Providers that aren't listed here can still be read — they're treated as
  /// implicitly registered the first time they are touched.
  Di({
    List<Provider> providers = const [],
    List<AsyncProvider> asyncProviders = const [],
  }) {
    for (final p in providers) {
      _knownSync.add(p);
    }
    for (final p in asyncProviders) {
      _knownAsync.add(p);
    }
  }

  final Set<Provider> _knownSync = {};
  final Set<AsyncProvider> _knownAsync = {};

  final Map<Provider, Function> _overrides = {};
  final Map<AsyncProvider, Function> _asyncOverrides = {};

  final Map<Provider, Object?> _appCache = {};
  final Map<AsyncProvider, Object?> _appCacheAsync = {};

  final List<FutureOr<void> Function()> _appDisposers = [];

  bool _disposed = false;

  /// Replaces [p]'s factory for the lifetime of this container.  Subsequent
  /// reads (and child request scopes) will use [factory] — useful for tests.
  void override<T>(Provider<T> p, T Function(DiRef di) factory) {
    _checkAlive();
    _overrides[p] = factory;
    _appCache.remove(p); // invalidate any prior cached value
  }

  /// Same as [override] but for an [AsyncProvider].
  void overrideAsync<T>(
      AsyncProvider<T> p, Future<T> Function(DiRef di) factory) {
    _checkAlive();
    _asyncOverrides[p] = factory;
    _appCacheAsync.remove(p);
  }

  /// Resolves an app-scoped synchronous provider.  Throws for request-scoped
  /// providers (use [_RequestScope.read] via `c.read`).
  //
  // No `@override` here: the `override` method defined above shadows the
  // `@override` annotation from `dart:core` inside this class.
  T read<T>(Provider<T> p) {
    _checkAlive();
    if (p.scope == Scope.request) {
      throw StateError(
          'Provider $p is request-scoped and cannot be read outside of a request');
    }
    if (_appCache.containsKey(p)) return _appCache[p] as T;
    final factory = (_overrides[p] as T Function(DiRef)?) ?? p.factory;
    final v = factory(this);
    _appCache[p] = v;
    _knownSync.add(p);
    final disposer = p.disposerFor(v);
    if (disposer != null) _appDisposers.add(disposer);
    return v;
  }

  /// Resolves an app-scoped asynchronous provider.
  Future<T> readAsync<T>(AsyncProvider<T> p) async {
    _checkAlive();
    if (p.scope == Scope.request) {
      throw StateError(
          'AsyncProvider $p is request-scoped and cannot be read outside of a request');
    }
    if (_appCacheAsync.containsKey(p)) return _appCacheAsync[p] as T;
    final factory =
        (_asyncOverrides[p] as Future<T> Function(DiRef)?) ?? p.factory;
    final v = await factory(this);
    _appCacheAsync[p] = v;
    _knownAsync.add(p);
    final disposer = p.disposerFor(v);
    if (disposer != null) _appDisposers.add(disposer);
    return v;
  }

  /// Eagerly instantiates every registered **app-scope** provider, running
  /// `onInit`-style work (any side effect inside the factory itself) before
  /// the first request hits.  Returns once every provider has been built.
  Future<void> warmup() async {
    _checkAlive();
    for (final p in _knownSync.toList()) {
      if (p.scope == Scope.app) read<dynamic>(p);
    }
    for (final p in _knownAsync.toList()) {
      if (p.scope == Scope.app) await readAsync<dynamic>(p);
    }
  }

  /// Runs every app-scope `onDispose` callback in **reverse creation order**
  /// (newest first), so a service can use its dependencies during cleanup.
  /// Safe to call multiple times — the second call is a no-op.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final d in _appDisposers.reversed) {
      await d();
    }
    _appDisposers.clear();
    _appCache.clear();
    _appCacheAsync.clear();
  }

  /// Returns the Darto middleware that opens a request scope per request,
  /// makes [contextProvider] readable inside that scope, and disposes any
  /// request-scope instances after the response is written.
  Middleware middleware() {
    return (Context c, Next next) async {
      final scope = _RequestScope(this, c);
      c.set(_diScopeKey, scope);
      try {
        await next();
      } finally {
        await scope._close();
      }
    };
  }

  void _checkAlive() {
    if (_disposed) throw StateError('Di has been disposed');
  }
}

class _RequestScope implements DiRef {
  _RequestScope(this._parent, this._ctx);

  final Di _parent;
  final Context _ctx;
  final Map<Provider, Object?> _cache = {};
  final Map<AsyncProvider, Object?> _cacheAsync = {};
  final List<FutureOr<void> Function()> _disposers = [];

  @override
  T read<T>(Provider<T> p) {
    if (identical(p, contextProvider)) return _ctx as T;
    if (p.scope == Scope.app) return _parent.read(p);
    if (_cache.containsKey(p)) return _cache[p] as T;
    final factory =
        (_parent._overrides[p] as T Function(DiRef)?) ?? p.factory;
    final v = factory(this);
    _cache[p] = v;
    _parent._knownSync.add(p);
    final disposer = p.disposerFor(v);
    if (disposer != null) _disposers.add(disposer);
    return v;
  }

  @override
  Future<T> readAsync<T>(AsyncProvider<T> p) async {
    if (p.scope == Scope.app) return _parent.readAsync(p);
    if (_cacheAsync.containsKey(p)) return _cacheAsync[p] as T;
    final factory =
        (_parent._asyncOverrides[p] as Future<T> Function(DiRef)?) ?? p.factory;
    final v = await factory(this);
    _cacheAsync[p] = v;
    _parent._knownAsync.add(p);
    final disposer = p.disposerFor(v);
    if (disposer != null) _disposers.add(disposer);
    return v;
  }

  Future<void> _close() async {
    for (final d in _disposers.reversed) {
      await d();
    }
    _disposers.clear();
    _cache.clear();
    _cacheAsync.clear();
  }
}

/// Reads providers off the current request — the main user-facing API.
extension ContextDi on Context {
  /// Resolves a synchronous [Provider] from the request's DI scope.
  T read<T>(Provider<T> p) {
    final scope = get<_RequestScope?>(_diScopeKey);
    if (scope == null) {
      throw StateError(
          'No DI scope on this request — did you forget app.use(container.middleware())?');
    }
    return scope.read(p);
  }

  /// Resolves an [AsyncProvider] from the request's DI scope.
  Future<T> readAsync<T>(AsyncProvider<T> p) {
    final scope = get<_RequestScope?>(_diScopeKey);
    if (scope == null) {
      throw StateError(
          'No DI scope on this request — did you forget app.use(container.middleware())?');
    }
    return scope.readAsync(p);
  }
}
