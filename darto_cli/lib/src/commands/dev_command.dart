import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

/// `darto dev` — run the server in development mode with fast restart on file changes.
Future<void> runDev(List<String> args) async {
  final entrypoint = _resolveEntrypoint(args);
  if (entrypoint == null) {
    stderr.writeln(
      '\x1B[31mError: No entrypoint found. '
      'Pass a file path or place your server in bin/server.dart.\x1B[0m',
    );
    exit(1);
  }

  stdout.writeln('\x1B[36m▶  darto dev\x1B[0m');
  stdout.writeln('\x1B[90m   entrypoint: $entrypoint\x1B[0m\n');

  Process? child;
  var killing = false;
  Timer? debounce;
  Timer? killTimer;
  final pendingChanges = <String>{};

  Future<void> startChild() async {
    if (child != null) {
      killing = true;
      killTimer?.cancel();
      child!.kill(ProcessSignal.sigterm);

      // Give the process 300 ms to shut down gracefully, then force-kill.
      final exitFuture = child!.exitCode;
      killTimer = Timer(const Duration(milliseconds: 300), () {
        child?.kill(ProcessSignal.sigkill);
      });
      await exitFuture;
      killTimer?.cancel();
      killing = false;
    }

    final sw = Stopwatch()..start();

    child = await Process.start(
      'dart',
      ['run', entrypoint],
      mode: ProcessStartMode.inheritStdio,
    );

    child!.exitCode.then((code) {
      if (!killing) {
        sw.stop();
        if (code != 0) {
          stderr.writeln('\n\x1B[31m[ERROR] Server exited with code $code\x1B[0m');
          stderr.writeln(
            '\x1B[90m   Fix the error above and save a file to restart.\x1B[0m',
          );
        }
      }
    });
  }

  await startChild();

  const ignoredSegments = {'.dart_tool', 'build', '.git'};

  final watchDirs = ['lib', 'bin', 'src'].where((d) => Directory(d).existsSync());

  for (final dir in watchDirs) {
    final watcher = DirectoryWatcher(dir);
    watcher.events.listen((event) {
      if (!event.path.endsWith('.dart')) return;

      final parts = p.split(event.path);
      if (parts.any(ignoredSegments.contains)) return;

      pendingChanges.add(p.relative(event.path));

      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 350), () async {
        final changed = pendingChanges.toList()..sort();
        pendingChanges.clear();

        if (changed.length == 1) {
          stdout.writeln('\n\x1B[33m↺  ${changed.first}\x1B[0m');
        } else {
          stdout.writeln('\n\x1B[33m↺  ${changed.length} files changed\x1B[0m');
          for (final f in changed) {
            stdout.writeln('\x1B[90m   • $f\x1B[0m');
          }
        }

        final sw = Stopwatch()..start();
        await startChild();
        sw.stop();
        stdout.writeln(
          '\x1B[90m   restarted in ${sw.elapsedMilliseconds}ms\x1B[0m',
        );
      });
    });
  }

  ProcessSignal.sigint.watch().listen((_) {
    debounce?.cancel();
    killTimer?.cancel();
    killing = true;
    child?.kill(ProcessSignal.sigterm);
    exit(0);
  });

  await child!.exitCode;
  await Completer<void>().future;
}

String? _resolveEntrypoint(List<String> args) {
  final explicit = args.firstWhere(
    (a) => a.endsWith('.dart') && !a.startsWith('-'),
    orElse: () => '',
  );
  if (explicit.isNotEmpty && File(explicit).existsSync()) return explicit;

  for (final c in ['bin/server.dart', 'bin/main.dart', 'lib/main.dart']) {
    if (File(c).existsSync()) return c;
  }
  return null;
}

class DevCommand extends Command<void> {
  @override
  final name = 'dev';

  @override
  final description =
      'Run server in development mode with auto-restart on file changes\n\nUsage: darto dev [entrypoint]';

  @override
  Future<void> run() => runDev(argResults!.rest);
}
