import 'dart:io';

import 'package:path/path.dart' as p;

import '../templates/di_templates.dart';
import '../utils.dart';

/// `darto gen feature <name> [--out lib/features]`
///
/// Scaffolds a single-file `Feature` (service + provider + routes) under
/// `lib/features/<name>/<name>_feature.dart`.
Future<void> runGenFeature(List<String> args) async {
  final positional = args.where((a) => !a.startsWith('-')).toList();
  if (positional.isEmpty) {
    _err('Missing feature name. Example: darto gen feature users');
  }
  final name = positional.first;
  final outRoot =
      _flag(args, '--out') ?? _flag(args, '-o') ?? p.join('lib', 'features');

  final snake = toSnakeCase(name);
  final dir = Directory(p.join(outRoot, snake));
  dir.createSync(recursive: true);

  final file = File(p.join(dir.path, '${snake}_feature.dart'));
  if (file.existsSync()) {
    _err('${p.relative(file.path)} already exists. Delete it first or pass --out.');
  }
  file.writeAsStringSync(featureTemplate(name));

  stdout.writeln('\x1B[32m✓  ${p.relative(file.path)}\x1B[0m');
  stdout.writeln('\x1B[90m   Add `darto_inject` to pubspec if not already present:\x1B[0m');
  stdout.writeln('\x1B[36m   dart pub add darto_inject\x1B[0m');
}

String? _flag(List<String> args, String flag) {
  final idx = args.indexOf(flag);
  if (idx == -1 || idx + 1 >= args.length) return null;
  return args[idx + 1];
}

Never _err(String msg) {
  stderr.writeln('\x1B[31m[ERROR] $msg\x1B[0m');
  exit(1);
}
