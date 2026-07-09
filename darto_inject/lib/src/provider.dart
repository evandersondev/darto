/// Lifetime of a provider's cached instance.
enum Scope {
  /// One instance for the whole app, kept until [Di.dispose] is called.
  app,

  /// One instance per request, disposed when the request finishes.
  request,
}

/// Reference passed to a provider factory — gives the factory typed access to
/// other providers in the same container.
abstract class DiRef {
  /// Resolves a synchronous [Provider]; throws if [p] hasn't been registered.
  T read<T>(Provider<T> p);

  /// Resolves an [AsyncProvider]; throws if [p] hasn't been registered.
  Future<T> readAsync<T>(AsyncProvider<T> p);
}

/// A typed factory for a value of type [T].
///
/// Providers are **identifiers** as much as factories: two providers
/// constructed with the same factory closure are still distinct keys in the
/// container.  Pass the same `final` provider variable everywhere to share
/// the cached instance.
///
/// ```dart
/// final dbProvider = Provider<Db>(
///   (di) => Db.connect(di.read(envProvider).dbUrl),
///   onDispose: (db) => db.close(),
/// );
/// ```
class Provider<T> {
  /// Builds the value; called at most once per scope.
  final T Function(DiRef di) factory;

  /// Lifetime of the cached value.  Defaults to [Scope.app].
  final Scope scope;

  /// Optional cleanup invoked when the owning scope is disposed.
  final void Function(T value)? onDispose;

  /// Optional human-readable name — shown in error messages and DevTools.
  final String? name;

  Provider(
    this.factory, {
    this.scope = Scope.app,
    this.onDispose,
    this.name,
  });

  /// Internal: builds a bound disposer for [value]. Runs as an instance method
  /// so it executes with this instance's reified `T`, avoiding the covariant
  /// field-read check that would fire if the container touched [onDispose] on a
  /// `Provider<dynamic>` view (e.g. during `warmup()`).
  void Function()? disposerFor(Object? value) {
    final d = onDispose;
    if (d == null) return null;
    return () => d(value as T);
  }

  @override
  String toString() => 'Provider<$T>${name == null ? '' : '($name)'}';
}

/// A typed factory for an asynchronous value of type [T].
///
/// Use this when the factory itself awaits something (a DB connect, a remote
/// fetch, etc.).  Read it with `c.readAsync(provider)` — `c.read` is reserved
/// for the synchronous variant so the call site is unambiguous about awaiting.
class AsyncProvider<T> {
  final Future<T> Function(DiRef di) factory;
  final Scope scope;
  final Future<void> Function(T value)? onDispose;
  final String? name;

  AsyncProvider(
    this.factory, {
    this.scope = Scope.app,
    this.onDispose,
    this.name,
  });

  /// Internal: builds a bound disposer for [value]. See [Provider.disposerFor].
  Future<void> Function()? disposerFor(Object? value) {
    final d = onDispose;
    if (d == null) return null;
    return () => d(value as T);
  }

  @override
  String toString() => 'AsyncProvider<$T>${name == null ? '' : '($name)'}';
}
