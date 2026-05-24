/// Environment variable loader for Darto.
///
/// Load once at startup, then access anywhere via typed getters:
///
/// ```dart
/// import 'package:darto_env/darto_env.dart';
///
/// void main() {
///   DartoEnv.load(); // reads .env file
///
///   final port   = DartoEnv.getInt('PORT', 3000);
///   final secret = DartoEnv.get('JWT_SECRET');
/// }
/// ```
library darto_env;

export 'src/darto_env_base.dart';
