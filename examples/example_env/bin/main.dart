import 'package:darto/darto.dart';
import 'package:darto_env/darto_env.dart';

void main() {
  // Load .env file at startup
  DartoEnv.load();

  final port    = DartoEnv.getInt('PORT', 3000);
  final appName = DartoEnv.get('APP_NAME', 'Darto App');
  final debug   = DartoEnv.getBool('DEBUG', false);

  final app = Darto();

  app.get('/', [], (Context c) => c.ok({
    'app': appName,
    'debug': debug,
    'port': port,
  }));

  app.get('/config', [], (Context c) {
    return c.ok({
      'APP_NAME': DartoEnv.get('APP_NAME', 'Darto App'),
      'PORT':     DartoEnv.getInt('PORT', 3000),
      'DEBUG':    DartoEnv.getBool('DEBUG', false),
      'DB_HOST':  DartoEnv.maybeGet('DB_HOST') ?? '(not set)',
    });
  });

  app.listen(port, () => print('$appName running on port $port (debug=$debug)'));
}
