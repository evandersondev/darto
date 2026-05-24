import 'package:darto_env/darto_env.dart';

class Env {
  static int get port => DartoEnv.getInt('PORT', 8080);
}
