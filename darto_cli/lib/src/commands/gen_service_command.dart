import 'dart:io';

import 'package:path/path.dart' as p;

import '../templates/di_templates.dart';
import '../utils.dart';

/// `darto gen service <name> [--out lib/services]`
///
/// Scaffolds a standalone service + provider — to drop into an existing
/// feature.  By default written to `lib/services/<name>_service.dart`.
Future<void> runGenService(List<String> args) async {
  final positional = args.where((a) => !a.startsWith('-')).toList();
  if (positional.isEmpty) {
    _err('Missing service name. Example: darto gen service users');
  }
  final name = positional.first;
  final outRoot =
      _flag(args, '--out') ?? _flag(args, '-o') ?? p.join('lib', 'services');

  final snake = toSnakeCase(name);
  Directory(outRoot).createSync(recursive: true);
  final file = File(p.join(outRoot, '${snake}_service.dart'));
  if (file.existsSync()) {
    _err('${p.relative(file.path)} already exists. Delete it first or pass --out.');
  }
  file.writeAsStringSync(serviceTemplate(name));

  stdout.writeln('\x1B[32m✓  ${p.relative(file.path)}\x1B[0m');
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
