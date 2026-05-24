import 'dart:io';

import 'package:args/command_runner.dart';

/// `darto build` — compile the server to a native executable and generate Docker artifacts.
Future<void> runBuild(List<String> args) async {
  final entrypoint = _resolveEntrypoint(args);
  if (entrypoint == null) {
    stderr.writeln('\x1B[31mError: No entrypoint found. '
        'Pass a file path or place your server in bin/server.dart.\x1B[0m');
    exit(1);
  }

  final output = _flag(args, '--output') ?? _flag(args, '-o') ?? 'build/server';
  final noDocker = args.contains('--no-docker');

  stdout.writeln('\x1B[36m⚙  Building $entrypoint → $output\x1B[0m');

  Directory(output).parent.createSync(recursive: true);

  final result = await Process.run(
    'dart',
    ['compile', 'exe', entrypoint, '-o', output],
    runInShell: true,
  );

  stdout.write(result.stdout);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(result.exitCode);
  }

  stdout.writeln('\x1B[32m✓  Build complete → $output\x1B[0m');
  stdout.writeln('\x1B[90m   Run with: darto start\x1B[0m');

  if (!noDocker) {
    _generateDockerArtifacts(entrypoint);
  }
}

void _generateDockerArtifacts(String entrypoint) {
  final dockerfilePath = 'Dockerfile';
  final dockerignorePath = '.dockerignore';

  if (!File(dockerfilePath).existsSync()) {
    File(dockerfilePath).writeAsStringSync(_dockerfileTemplate(entrypoint));
    stdout.writeln('\x1B[32m✓  Generated Dockerfile\x1B[0m');
  } else {
    stdout.writeln('\x1B[90m   Dockerfile already exists — skipped.\x1B[0m');
  }

  if (!File(dockerignorePath).existsSync()) {
    File(dockerignorePath).writeAsStringSync(_dockerignoreTemplate());
    stdout.writeln('\x1B[32m✓  Generated .dockerignore\x1B[0m');
  } else {
    stdout.writeln('\x1B[90m   .dockerignore already exists — skipped.\x1B[0m');
  }

  stdout.writeln('\x1B[90m\n   Docker build: docker build -t my_app .\x1B[0m');
  stdout.writeln('\x1B[90m   Docker run:   docker run -p 3000:3000 my_app\x1B[0m');
}

String _dockerfileTemplate(String entrypoint) => '''
# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM dart:stable AS build

WORKDIR /app

# Cache pub dependencies separately from source for faster rebuilds
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart compile exe $entrypoint -o bin/server

# ── Stage 2: Minimal runtime ──────────────────────────────────────────────────
# Uses scratch + Dart /runtime/ — significantly smaller than debian:slim
FROM scratch

# Dart AOT runtime — minimal shared libs (libc, libpthread, libm, libdl)
COPY --from=build /runtime/ /

# CA certificates for outbound HTTPS requests
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=build /app/bin/server /app/server

EXPOSE 3000

CMD ["/app/server"]
''';

String _dockerignoreTemplate() => '''
.dart_tool/
.git/
.gitignore
.env
build/
test/
*.md
pubspec.lock
''';


/// `darto start` — run the compiled executable.
Future<void> runStart(List<String> args) async {
  final binary = args.firstWhere(
    (a) => !a.startsWith('-'),
    orElse: () => 'build/server',
  );

  if (!File(binary).existsSync()) {
    stderr.writeln('\x1B[31mError: Binary "$binary" not found.\x1B[0m');
    stderr.writeln('\x1B[90m   Compile it first with:\x1B[0m');
    stderr.writeln('\x1B[36m     darto build\x1B[0m');
    exit(1);
  }

  stdout.writeln('\x1B[36m▶  Starting $binary\x1B[0m\n');

  final process = await Process.start(
    binary,
    [],
    mode: ProcessStartMode.inheritStdio,
  );

  ProcessSignal.sigint.watch().listen((_) {
    process.kill();
    exit(0);
  });

  exit(await process.exitCode);
}

// ── helpers ───────────────────────────────────────────────────────────────────

String? _resolveEntrypoint(List<String> args) {
  final explicit = args.firstWhere(
    (a) => a.endsWith('.dart') && !a.startsWith('-'),
    orElse: () => '',
  );
  if (explicit.isNotEmpty && File(explicit).existsSync()) return explicit;

  for (final c in ['bin/server.dart', 'bin/main.dart']) {
    if (File(c).existsSync()) return c;
  }
  return null;
}

String? _flag(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i == -1 || i + 1 >= args.length) return null;
  return args[i + 1];
}

class BuildCommand extends Command<void> {
  @override
  final name = 'build';

  @override
  final description =
      'Compile server to a native executable and generate Docker artifacts\n\nUsage: darto build [entrypoint] [--output <path>] [--no-docker]';

  BuildCommand() {
    argParser
      ..addOption('output', abbr: 'o', help: 'Output binary path', defaultsTo: 'build/server')
      ..addFlag('no-docker', help: 'Skip Dockerfile generation', defaultsTo: false);
  }

  @override
  Future<void> run() {
    final output = argResults!['output'] as String;
    final noDocker = argResults!['no-docker'] as bool;
    return runBuild([
      ...argResults!.rest,
      '--output', output,
      if (noDocker) '--no-docker',
    ]);
  }
}

class StartCommand extends Command<void> {
  @override
  final name = 'start';

  @override
  final description =
      'Run the compiled server binary\n\nUsage: darto start [binary]';

  @override
  Future<void> run() => runStart(argResults!.rest);
}
