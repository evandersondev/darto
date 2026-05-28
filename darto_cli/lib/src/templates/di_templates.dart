/// Templates for `darto gen feature|service <name>` — the darto_di scaffolds.
library;

import '../utils.dart';

/// Single-file [Feature] scaffold: service + provider + Feature with one
/// example route, all wired together.  The user splits the file as the
/// feature grows.
String featureTemplate(String name) {
  final pascal = toPascalCase(name);
  final camel = toCamelCase(name);
  final snake = toSnakeCase(name);
  return '''
import 'package:darto/darto.dart';
import 'package:darto_di/darto_di.dart';

// ── Service ──────────────────────────────────────────────────────────────────

class ${pascal}Service {
  Future<List<Map<String, dynamic>>> list() async {
    // TODO: replace with a real data source.
    return [];
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final ${camel}ServiceProvider = Provider<${pascal}Service>(
  (di) => ${pascal}Service(),
);

// ── Feature ──────────────────────────────────────────────────────────────────
//
// Register at boot:
//
//   final di = Di(providers: [...${camel}Feature.providers]);
//   app
//     ..use(di.middleware())
//     ..install('/api', ${camel}Feature);
//
final ${camel}Feature = Feature(
  providers: [${camel}ServiceProvider],
  routes: (r) {
    r.get('/${snake}', [], (c) async {
      final svc = c.read(${camel}ServiceProvider);
      return c.ok(await svc.list());
    });
  },
);
''';
}

/// Standalone service + provider — drop in when you want to add a service to
/// an existing feature without scaffolding a whole `Feature` again.
String serviceTemplate(String name) {
  final pascal = toPascalCase(name);
  final camel = toCamelCase(name);
  return '''
import 'package:darto_di/darto_di.dart';

class ${pascal}Service {
  // TODO: implement.
}

/// Register this provider on your `Di` container, or include it in a Feature's
/// `providers` list.
final ${camel}ServiceProvider = Provider<${pascal}Service>(
  (di) => ${pascal}Service(),
);
''';
}
