import 'dart:io';

import 'package:darto/darto.dart';

// ── ANSI helpers ──────────────────────────────────────────────────────────────

const _reset = '\x1B[0m';
const _bold = '\x1B[1m';
const _dim = '\x1B[2m';
const _green = '\x1B[32m';
const _blue = '\x1B[34m';
const _yellow = '\x1B[33m';
const _cyan = '\x1B[36m';
const _red = '\x1B[31m';
const _magenta = '\x1B[35m';
const _white = '\x1B[37m';

String _methodColor(String method) => switch (method) {
      'GET' => _green,
      'POST' => _blue,
      'PUT' => _yellow,
      'PATCH' => _cyan,
      'DELETE' => _red,
      'HEAD' => _white,
      'OPTIONS' => _magenta,
      _ => '',
    };

// ── Public API ────────────────────────────────────────────────────────────────

/// Returns the name of the Darto router implementation.
///
/// Mirrors the Hono `getRouterName` helper for API familiarity.
///
/// ```dart
/// final app = Darto();
/// print(getRouterName(app)); // 'Darto'
/// ```
String getRouterName(Darto app) => 'Darto';

/// Prints all registered routes to stdout.
///
/// - [verbose]: appends the number of per-route middlewares when > 0
/// - [colorize]: wraps HTTP method labels in ANSI colour codes
///
/// ```dart
/// final app = Darto().basePath('/v1');
///
/// app.get('/posts', handler);
/// app.get('/posts/:id', handler);
/// app.post('/posts', handler);
///
/// showRoutes(app, colorize: true);
/// // GET     /v1/posts
/// // GET     /v1/posts/:id
/// // POST    /v1/posts
/// ```
void showRoutes(
  Darto app, {
  bool verbose = false,
  bool colorize = false,
}) {
  final entries = app.routeEntries;

  if (entries.isEmpty) {
    stdout.writeln('No routes registered.');
    return;
  }

  for (final e in entries) {
    // Pad the raw method first, then wrap in colour so ANSI codes don't
    // distort the visual alignment.
    final padded = e.method.padRight(7);
    final label =
        colorize ? '$_bold${_methodColor(e.method)}$padded$_reset' : padded;

    final mwSuffix = (verbose && e.middlewareCount > 0)
        ? (colorize
            ? '  $_dim[${e.middlewareCount} mw]$_reset'
            : '  [${e.middlewareCount} mw]')
        : '';

    stdout.writeln('$label ${e.path}$mwSuffix');
  }
}
