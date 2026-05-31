import 'dart:convert';
import 'dart:io';

/// Severity levels, ordered from least to most severe.
enum LogLevel { debug, info, warn, error }

/// A small structured logger.
///
/// Emits one entry per line — JSON by default, or human-readable when [pretty].
/// Bind contextual fields (e.g. a request id) with [child] so they appear on
/// every line.
///
/// ```dart
/// final log = Logger(minLevel: LogLevel.debug);
/// log.info('server started', {'port': 3000});
/// log.error('db failed', error: e, stackTrace: s);
///
/// final reqLog = log.child({'requestId': id});
/// reqLog.info('handled', {'status': 200});
/// ```
class Logger {
  /// Entries below this level are dropped.
  final LogLevel minLevel;

  /// When true, prints a human-readable line instead of JSON.
  final bool pretty;

  final Map<String, dynamic> _bound;
  final void Function(String line) _out;

  Logger({
    this.minLevel = LogLevel.info,
    this.pretty = false,
    void Function(String line)? output,
  })  : _bound = const {},
        _out = output ?? _stdout;

  Logger._(this.minLevel, this.pretty, this._bound, this._out);

  static void _stdout(String line) => stdout.writeln(line);

  /// Returns a logger that includes [fields] on every line.
  Logger child(Map<String, dynamic> fields) =>
      Logger._(minLevel, pretty, {..._bound, ...fields}, _out);

  void debug(String message, [Map<String, dynamic>? fields]) =>
      _log(LogLevel.debug, message, fields);

  void info(String message, [Map<String, dynamic>? fields]) =>
      _log(LogLevel.info, message, fields);

  void warn(String message, [Map<String, dynamic>? fields]) =>
      _log(LogLevel.warn, message, fields);

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? fields,
  }) =>
      _log(LogLevel.error, message, {
        ...?fields,
        if (error != null) 'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      });

  void _log(LogLevel level, String message, Map<String, dynamic>? fields) {
    if (level.index < minLevel.index) return;
    final entry = <String, dynamic>{
      'ts': DateTime.now().toUtc().toIso8601String(),
      'level': level.name,
      'msg': message,
      ..._bound,
      ...?fields,
    };
    _out(pretty ? _formatPretty(entry) : jsonEncode(entry));
  }

  String _formatPretty(Map<String, dynamic> e) {
    final level = (e['level'] as String).toUpperCase().padRight(5);
    final extra = Map<String, dynamic>.from(e)
      ..removeWhere((k, _) => k == 'ts' || k == 'level' || k == 'msg');
    final kv = extra.entries.map((x) => '${x.key}=${x.value}').join(' ');
    return '${e['ts']} $level ${e['msg']}${kv.isEmpty ? '' : '  $kv'}';
  }
}
