import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../templates/module_templates.dart';
import '../templates/project_templates.dart';
import '../utils.dart';

/// `darto create <name> [--blank]` — scaffold a new Darto project.
Future<void> runCreate(List<String> args, {bool blank = false}) async {
  if (args.isEmpty) {
    _err('Usage: darto create <project-name> [--blank]');
    return;
  }

  final name = toSnakeCase(args.first);
  final dir = Directory(p.join(Directory.current.path, name));

  if (dir.existsSync()) {
    _err('Directory "$name" already exists.');
    return;
  }

  _log('Creating project "$name"${blank ? ' (blank)' : ''}...');

  // ── directory tree ──────────────────────────────────────────────────────────
  final paths = [
    'bin',
    'lib',
    if (!blank) 'lib/modules/user',
  ];
  for (final rel in paths) {
    Directory(p.join(dir.path, rel)).createSync(recursive: true);
  }

  // ── files ───────────────────────────────────────────────────────────────────
  _write(dir, 'pubspec.yaml', pubspecTemplate(name));
  _write(dir, 'analysis_options.yaml', analysisOptionsTemplate());
  _write(dir, 'bin/server.dart', serverTemplate(name));
  _write(dir, 'lib/app.dart', blank ? blankAppTemplate() : appTemplate(name));

  if (!blank) {
    const mod = 'user';
    _write(dir, 'lib/modules/$mod/${mod}_controller.dart', controllerTemplate(mod));
    _write(dir, 'lib/modules/$mod/${mod}_service.dart', serviceTemplate(mod));
  }

  _log('Running dart pub get...');
  final pubResult = await Process.run(
    'dart',
    ['pub', 'get'],
    workingDirectory: dir.path,
    runInShell: true,
  );

  if (pubResult.exitCode != 0) {
    _warn('dart pub get failed. Enter the project folder and run it manually:');
    _warn('  cd $name && dart pub get');
    stderr.write(pubResult.stderr);
  }

  _ok('''
Project "$name" created successfully!

  cd $name
  darto dev
''');
}

// ── helpers ──────────────────────────────────────────────────────────────────

void _write(Directory root, String rel, String content) {
  final file = File(p.join(root.path, rel));
  file.writeAsStringSync(content);
  _log('  created $rel');
}

void _log(String msg) => stdout.writeln('\x1B[90m$msg\x1B[0m');
void _ok(String msg) => stdout.writeln('\x1B[32m$msg\x1B[0m');
void _warn(String msg) => stdout.writeln('\x1B[33mWARN: $msg\x1B[0m');
void _err(String msg) {
  stderr.writeln('\x1B[31mError: $msg\x1B[0m');
  exit(1);
}

class CreateCommand extends Command<void> {
  CreateCommand() {
    argParser.addFlag(
      'blank',
      abbr: 'b',
      negatable: false,
      help: 'Create a minimal project without a starter module.',
    );
  }

  @override
  final name = 'create';

  @override
  final description =
      'Scaffold a new Darto project\n\nUsage: darto create <name> [--blank|-b]';

  @override
  Future<void> run() => runCreate(
        argResults!.rest,
        blank: argResults!.flag('blank'),
      );
}
