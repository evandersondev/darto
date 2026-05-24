/// Templates for `darto create <name>`.
library;

String pubspecTemplate(String name) => '''
name: $name
description: A Darto web application
version: 0.0.1
publish_to: none

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  darto: ^0.1.0

dev_dependencies:
  lints: ^5.0.0
  test: ^1.24.0
''';

String serverTemplate(String name) => '''
import 'package:$name/app.dart';

void main() async {
  final app = createApp();
  await app.listen(3000, () => print('Server running on http://localhost:3000'));
}
''';

/// Full app.dart — includes a starter user module.
String appTemplate(String name) => '''
import 'package:darto/cors.dart';
import 'package:darto/darto.dart';

import 'modules/user/user_controller.dart';

Darto createApp() {
  final app = Darto();

  app.use(cors());

  app.route('/users', userRouter);

  app.onError((err, c) => c.internalError({'error': err.message}));
  app.notFound((Context c) => c.notFound({'error': 'Route not found'}));

  return app;
}
''';

/// Minimal app.dart — no modules, just a health-check route.
String blankAppTemplate() => '''
import 'package:darto/darto.dart';

Darto createApp() {
  final app = Darto();

  app.get('/health', [], (Context c) => c.ok({'status': 'ok'}));

  app.onError((err, c) => c.internalError({'error': err.message}));
  app.notFound((Context c) => c.notFound({'error': 'Route not found'}));

  return app;
}
''';

String analysisOptionsTemplate() => '''
include: package:lints/recommended.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
''';
