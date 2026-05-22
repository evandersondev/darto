import 'package:darto/src/core/darto_base.dart';

/// API key authentication middleware.
///
/// Reads the key from [header] (default `x-api-key`) and validates it
/// using [validate]. On success calls [next]; on failure responds with 401.
///
/// ```dart
/// // Static key
/// app.mount('/api/*', apiKeyAuth(validate: (key) => key == env.apiKey));
///
/// // Multiple valid keys
/// final validKeys = {'key-a', 'key-b'};
/// app.mount('/api/*', apiKeyAuth(validate: validKeys.contains));
///
/// // Custom header
/// app.mount('/webhooks', apiKeyAuth(
///   header: 'x-webhook-secret',
///   validate: (key) => key == env.webhookSecret,
/// ));
/// ```
Middleware apiKeyAuth({
  required bool Function(String key) validate,
  String header = 'x-api-key',
}) {
  return (Context c, Next next) async {
    final key = c.req.header(header);

    if (key == null || key.isEmpty) {
      c.status(401).json({'error': 'Unauthorized', 'message': 'Missing API key'});
      return;
    }

    if (!validate(key)) {
      c.status(401).json({'error': 'Unauthorized', 'message': 'Invalid API key'});
      return;
    }

    await next();
  };
}
