import 'dart:convert';

import 'package:darto/src/core/darto_base.dart';

Middleware basicAuth({
  String? username,
  String? password,
  bool Function(String username, String password, Context c)? verifyUser,
  void Function(Context c, String username)? onAuthSuccess,
  String realm = 'Secure Area',
}) {
  return (Context c, Next next) async {
    final header = c.req.header('authorization');

    if (header == null || !header.startsWith('Basic ')) {
      _unauthorized(c, realm);
      return;
    }

    final encoded = header.substring(6);
    final decoded = utf8.decode(base64.decode(encoded));
    final parts = decoded.split(':');

    if (parts.length != 2) {
      _unauthorized(c, realm);
      return;
    }

    final user = parts[0];
    final pass = parts[1];

    final valid = verifyUser != null
        ? verifyUser(user, pass, c)
        : (user == username && pass == password);

    if (!valid) {
      _unauthorized(c, realm);
      return;
    }

    onAuthSuccess?.call(c, user);

    await next();
  };
}

void _unauthorized(Context c, String realm) {
  c.status(401);
  c.res.setHeader('WWW-Authenticate', 'Basic realm="$realm"');
  c.json({'error': 'Unauthorized'});
}
