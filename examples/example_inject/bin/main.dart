import 'package:darto/darto.dart';
import 'package:darto_inject/darto_inject.dart';

// ── A service and its provider ──────────────────────────────────────────────

class UserService {
  final _users = <int, Map<String, dynamic>>{
    1: {'id': 1, 'name': 'Alice'},
    2: {'id': 2, 'name': 'Bob'},
  };

  List<Map<String, dynamic>> list() => _users.values.toList();
  Map<String, dynamic>? find(int id) => _users[id];
}

// App-scope: built once, shared by every request.
final userServiceProvider = Provider<UserService>((di) => UserService());

// Request-scope: rebuilt per request. contextProvider gives the factory access
// to the current Context (here: read an incoming header).
final requestIdProvider = Provider<String>(
  (di) => di.read(contextProvider).req.header('x-request-id') ?? 'none',
  scope: Scope.request,
);

void main() async {
  // Build the container, eagerly warm app-scope singletons, then expose it to
  // handlers via middleware.
  final di = Di(providers: [userServiceProvider, requestIdProvider]);
  await di.warmup();

  final app = Darto()..use(di.middleware());

  app.get('/users', [], (Context c) {
    final svc = c.read(userServiceProvider); // same instance every request
    return c.ok(svc.list());
  });

  app.get('/users/:id', [], (Context c) {
    final user = c.read(userServiceProvider).find(c.req.paramInt('id') ?? 0);
    return user == null ? c.notFound({'error': 'not found'}) : c.ok(user);
  });

  app.get('/whoami', [], (Context c) {
    // Resolved fresh per request from the X-Request-Id header.
    return c.ok({'requestId': c.read(requestIdProvider)});
  });

  await app.listen(3000, () => print('DI example on http://localhost:3000'));
}
