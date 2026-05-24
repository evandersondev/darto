import 'package:darto/src/core/darto_base.dart';

/// RBAC middleware — verifies that the authenticated user has **all** of [roles].
///
/// Must be placed **after** a JWT or bearer-auth middleware that populates
/// `c.user`. Reads `c.user['roles']` which must be a `List<String>`.
///
/// ```dart
/// app.delete('/posts/:id', [
///   jwt(secret: env.secret),
///   requireRoles(['admin']),
/// ], deleteHandler);
///
/// // Multiple roles — user must have ALL of them
/// app.get('/reports', [
///   jwt(secret: env.secret),
///   requireRoles(['admin', 'auditor']),
/// ], handler);
/// ```
Middleware requireRoles(List<String> roles) {
  return (Context c, Next next) async {
    final user = c.user;

    if (user == null) {
      c.status(403).json({'error': 'Forbidden', 'message': 'Not authenticated'});
      return;
    }

    final userRoles = (user['roles'] as List?)?.cast<String>() ?? <String>[];
    final missing = roles.where((r) => !userRoles.contains(r)).toList();

    if (missing.isNotEmpty) {
      c.status(403).json({
        'error': 'Forbidden',
        'message': 'Missing required roles: $missing',
      });
      return;
    }

    await next();
  };
}
