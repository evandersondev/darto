import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../templates/module_templates.dart';
import '../templates/project_templates.dart';
import '../utils.dart';

/// The available project templates for `darto create`.
enum ProjectTemplate {
  /// Starter project with an example `user` module (controller + service).
  standard,

  /// Minimal project — just a health-check route.
  blank,

  /// REST API where one zard schema validates the request AND generates the
  /// OpenAPI 3.1 document (served with the Scalar UI at /docs).
  openapi;

  static ProjectTemplate? parse(String value) {
    switch (value.toLowerCase()) {
      case 'default':
      case 'standard':
        return ProjectTemplate.standard;
      case 'blank':
        return ProjectTemplate.blank;
      case 'openapi':
        return ProjectTemplate.openapi;
    }
    return null;
  }
}

/// `darto create <name> [--template <t>]` — scaffold a new Darto project.
///
/// [blank] is kept for backward compatibility; [template] takes precedence.
Future<void> runCreate(
  List<String> args, {
  bool blank = false,
  ProjectTemplate? template,
}) async {
  if (args.isEmpty) {
    _err('Usage: darto create <project-name> [--template default|blank|openapi]');
    return;
  }

  final tpl =
      template ?? (blank ? ProjectTemplate.blank : ProjectTemplate.standard);

  final name = toSnakeCase(args.first);
  final dir = Directory(p.join(Directory.current.path, name));

  if (dir.existsSync()) {
    _err('Directory "$name" already exists.');
    return;
  }

  _log('Creating project "$name" (${tpl.name})...');

  switch (tpl) {
    case ProjectTemplate.openapi:
      _scaffoldOpenapi(dir, name);
      break;
    case ProjectTemplate.blank:
      _scaffoldStandard(dir, name, withModule: false);
      break;
    case ProjectTemplate.standard:
      _scaffoldStandard(dir, name, withModule: true);
      break;
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

// ── scaffolders ───────────────────────────────────────────────────────────────

/// The `standard` / `blank` templates (Context-based app, optional user module).
void _scaffoldStandard(Directory dir, String name, {required bool withModule}) {
  final paths = ['bin', 'lib', if (withModule) 'lib/modules/user'];
  for (final rel in paths) {
    Directory(p.join(dir.path, rel)).createSync(recursive: true);
  }

  _write(dir, 'pubspec.yaml', pubspecTemplate(name));
  _write(dir, 'analysis_options.yaml', analysisOptionsTemplate());
  _write(dir, '.gitignore', gitignoreTemplate());
  _write(dir, 'bin/server.dart', serverTemplate(name));
  _write(dir, 'lib/app.dart',
      withModule ? appTemplate(name) : blankAppTemplate());

  if (withModule) {
    const mod = 'user';
    _write(dir, 'lib/modules/$mod/${mod}_controller.dart',
        controllerTemplate(mod));
    _write(dir, 'lib/modules/$mod/${mod}_service.dart', serviceTemplate(mod));
  }
}

/// The `openapi` template — one zard schema validates AND documents the API.
void _scaffoldOpenapi(Directory dir, String name) {
  for (final rel in ['bin', 'lib/schemas', 'test']) {
    Directory(p.join(dir.path, rel)).createSync(recursive: true);
  }

  _write(dir, 'pubspec.yaml', openapiPubspecTemplate(name));
  _write(dir, 'analysis_options.yaml', analysisOptionsTemplate());
  _write(dir, '.gitignore', gitignoreTemplate());
  _write(dir, 'bin/server.dart', serverTemplate(name));
  _write(dir, 'lib/app.dart', openapiAppTemplate(name));
  _write(dir, 'lib/schemas/user_schema.dart', openapiUserSchemaTemplate());
  _write(dir, 'test/app_test.dart', openapiTestTemplate(name));
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
    argParser
      ..addOption(
        'template',
        abbr: 't',
        allowed: ['default', 'blank', 'openapi'],
        allowedHelp: {
          'default': 'Starter project with an example user module.',
          'blank': 'Minimal project — just a health-check route.',
          'openapi':
              'REST API where one zard schema validates AND generates OpenAPI 3.1 docs.',
        },
        help: 'Project template to scaffold.',
      )
      ..addFlag(
        'blank',
        abbr: 'b',
        negatable: false,
        help: 'Alias for --template blank.',
      );
  }

  @override
  final name = 'create';

  @override
  final description =
      'Scaffold a new Darto project\n\nUsage: darto create <name> [--template default|blank|openapi]';

  @override
  Future<void> run() {
    final raw = argResults!.option('template');
    ProjectTemplate? template;
    if (raw != null) {
      template = ProjectTemplate.parse(raw);
      if (template == null) {
        stderr.writeln('\x1B[31mError: unknown template "$raw". '
            'Use one of: default, blank, openapi.\x1B[0m');
        exit(1);
      }
    }
    return runCreate(
      argResults!.rest,
      blank: argResults!.flag('blank'),
      template: template,
    );
  }
}
