import 'dart:io';

import 'commands/build_command.dart';
import 'commands/create_command.dart';
import 'commands/dev_command.dart';
import 'commands/gen_client_command.dart';
import 'commands/gen_feature_command.dart';
import 'commands/gen_service_command.dart';

const _version = '0.0.1';

const _help = '''
\x1B[36mDarto CLI\x1B[0m — Official CLI for the Darto framework

\x1B[1mUsage:\x1B[0m  darto <command> [arguments]

\x1B[1mCommands:\x1B[0m
  create <name>          Scaffold a new Darto project
  create <name> --blank  Scaffold a minimal project (no starter module)
  dev [entrypoint]       Run server in development mode (auto-restart)
  build [entrypoint]     Compile server to native executable + generate Dockerfile
  start [binary]         Run the compiled binary

  gen client flutter     Generate a typed Flutter/Dart HTTP client
  gen feature <name>     Scaffold a darto_inject Feature (service + provider + routes)
  gen service <name>     Scaffold a standalone service + provider

\x1B[1mOptions:\x1B[0m
  -h, --help             Show this help
  -v, --version          Show version

\x1B[1mExamples:\x1B[0m
  darto create my_api
  darto create my_api --blank
  darto dev
  darto gen client flutter
  darto gen feature users
  darto gen service mailer
  darto build --output build/server
  darto start build/server
''';

Future<void> runCli(List<String> args) async {
  if (args.isEmpty || args.first == '--help' || args.first == '-h') {
    stdout.write(_help);
    return;
  }

  if (args.first == '--version' || args.first == '-v') {
    stdout.writeln('darto_cli v$_version');
    return;
  }

  final command = args.first;
  final rest = args.skip(1).toList();

  switch (command) {
    case 'create':
      final blank = rest.contains('--blank') || rest.contains('-b');
      final nameArgs = rest.where((a) => !a.startsWith('-')).toList();
      await runCreate(nameArgs, blank: blank);
    case 'dev':
      await runDev(rest);
    case 'build':
      await runBuild(rest);
    case 'start':
      await runStart(rest);
    case 'gen':
      await _runGen(rest);
    default:
      stderr.writeln('\x1B[31mUnknown command "$command".\x1B[0m');
      stderr.writeln('Run \x1B[36mdarto --help\x1B[0m for available commands.');
      exit(1);
  }
}

/// Dispatches `darto gen <subcommand> [args]`.
Future<void> _runGen(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('\x1B[31mError: Missing gen subcommand.\x1B[0m');
    stderr.writeln('Example: darto gen client flutter');
    exit(1);
  }

  final sub = args.first;
  final rest = args.skip(1).toList();

  switch (sub) {
    case 'client':
      await runGenClient(rest);
    case 'feature':
      await runGenFeature(rest);
    case 'service':
      await runGenService(rest);
    default:
      stderr.writeln('\x1B[31mUnknown gen subcommand "$sub".\x1B[0m');
      stderr.writeln('Available: client, feature, service');
      exit(1);
  }
}
