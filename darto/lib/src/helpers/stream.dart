import 'dart:async';
import 'dart:io';

import 'package:darto/src/core/darto_base.dart';
import 'package:darto/src/core/darto_response.dart';

// ── SseEvent ──────────────────────────────────────────────────────────────────

/// Payload for a single Server-Sent Event.
///
/// ```dart
/// await writer.writeSSE(SseEvent(
///   event: 'update',
///   data: jsonEncode({'count': 42}),
///   id: '1',
/// ));
/// ```
class SseEvent {
  final String data;
  final String? event;
  final String? id;

  /// Reconnection delay in milliseconds sent to the client.
  final int? retry;

  const SseEvent({required this.data, this.event, this.id, this.retry});
}

// ── DartoStreamWriter ─────────────────────────────────────────────────────────

/// Writer for raw binary streaming via [stream].
class DartoStreamWriter {
  final HttpResponse _res;
  void Function()? _onAbortCallback;
  bool _aborted = false;

  DartoStreamWriter._(this._res);

  /// Registers [callback] to be called when the client disconnects.
  void onAbort(void Function() callback) => _onAbortCallback = callback;

  /// Sends a binary [chunk] immediately.
  Future<void> write(List<int> chunk) async {
    if (_aborted) return;
    try {
      _res.add(chunk);
      await _res.flush();
    } on SocketException {
      _aborted = true;
      _onAbortCallback?.call();
    }
  }

  /// Pipes a binary [source] stream into the response.
  Future<void> pipe(Stream<List<int>> source) async {
    await for (final chunk in source) {
      if (_aborted) break;
      await write(chunk);
    }
  }
}

// ── DartoTextStreamWriter ─────────────────────────────────────────────────────

/// Writer for plain-text streaming via [streamText].
class DartoTextStreamWriter {
  final HttpResponse _res;
  bool _aborted = false;

  DartoTextStreamWriter._(this._res);

  /// Sends [text] without a trailing newline.
  Future<void> write(String text) async {
    if (_aborted) return;
    try {
      _res.write(text);
      await _res.flush();
    } on SocketException {
      _aborted = true;
    }
  }

  /// Sends [text] followed by a newline character.
  Future<void> writeln(String text) => write('$text\n');

  /// Pauses the stream for [duration].
  Future<void> sleep(Duration duration) => Future.delayed(duration);

  /// Pipes a text [source] stream into the response.
  Future<void> pipe(Stream<String> source) async {
    await for (final chunk in source) {
      if (_aborted) break;
      await write(chunk);
    }
  }
}

// ── DartoSSEWriter ────────────────────────────────────────────────────────────

/// Writer for Server-Sent Events via [streamSSE].
class DartoSSEWriter {
  final HttpResponse _res;
  void Function()? _onAbortCallback;
  bool _aborted = false;

  DartoSSEWriter._(this._res);

  /// Registers [callback] to be called when the client disconnects.
  void onAbort(void Function() callback) => _onAbortCallback = callback;

  /// Sends a structured SSE [event] to the client.
  ///
  /// Multi-line [SseEvent.data] is split and prefixed correctly per the spec.
  Future<void> writeSSE(SseEvent event) async {
    if (_aborted) return;
    try {
      final buf = StringBuffer();
      if (event.id != null) buf.writeln('id: ${event.id}');
      if (event.event != null) buf.writeln('event: ${event.event}');
      if (event.retry != null) buf.writeln('retry: ${event.retry}');
      for (final line in event.data.split('\n')) {
        buf.writeln('data: $line');
      }
      buf.writeln(); // blank line terminates the event
      _res.write(buf.toString());
      await _res.flush();
    } on SocketException {
      _aborted = true;
      _onAbortCallback?.call();
    }
  }

  /// Pauses the event stream for [duration].
  Future<void> sleep(Duration duration) => Future.delayed(duration);
}

// ── stream ────────────────────────────────────────────────────────────────────

/// Streams raw binary data to the client.
///
/// Sets `Transfer-Encoding: chunked` automatically. The [callback] receives a
/// [DartoStreamWriter] to send chunks. Errors in [callback] are forwarded to
/// [onError]; without it they are silently swallowed (the response is always
/// closed cleanly).
///
/// ```dart
/// app.get('/bytes', (c) => stream(c, (s) async {
///   await s.write([72, 101, 108, 108, 111]);
/// }));
/// ```
Future<Response> stream(
  Context c,
  Future<void> Function(DartoStreamWriter writer) callback, {
  Future<void> Function(Object error, DartoStreamWriter writer)? onError,
}) async {
  final httpRes = c.res.raw;
  httpRes.statusCode = 200;
  httpRes.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');

  final writer = DartoStreamWriter._(httpRes);
  unawaited(httpRes.done.then((_) {}, onError: (_) {
    writer._aborted = true;
    writer._onAbortCallback?.call();
  }));

  try {
    await callback(writer);
  } catch (e) {
    if (onError != null) await onError(e, writer);
  } finally {
    try {
      await httpRes.close();
    } catch (_) {}
  }

  return const Response.sent();
}

// ── streamText ────────────────────────────────────────────────────────────────

/// Streams plain text to the client chunk by chunk.
///
/// Sets `Content-Type: text/plain` and `Transfer-Encoding: chunked`
/// automatically. The [callback] receives a [DartoTextStreamWriter].
///
/// ```dart
/// app.get('/words', (c) => streamText(c, (s) async {
///   for (final word in ['Hello', ' ', 'World']) {
///     await s.write(word);
///     await s.sleep(Duration(milliseconds: 300));
///   }
/// }));
/// ```
Future<Response> streamText(
  Context c,
  Future<void> Function(DartoTextStreamWriter writer) callback, {
  Future<void> Function(Object error, DartoTextStreamWriter writer)? onError,
}) async {
  final httpRes = c.res.raw;
  httpRes.statusCode = 200;
  httpRes.headers.contentType = ContentType.text;
  httpRes.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');

  final writer = DartoTextStreamWriter._(httpRes);

  try {
    await callback(writer);
  } catch (e) {
    if (onError != null) await onError(e, writer);
  } finally {
    try {
      await httpRes.close();
    } catch (_) {}
  }

  return const Response.sent();
}

// ── streamSSE ─────────────────────────────────────────────────────────────────

/// Streams Server-Sent Events (SSE) to the client.
///
/// Sets `Content-Type: text/event-stream`, `Cache-Control: no-cache`,
/// `Connection: keep-alive`, and `X-Accel-Buffering: no` (disables Nginx
/// proxy buffering) automatically. The [callback] receives a [DartoSSEWriter].
///
/// ```dart
/// app.get('/events', (c) => streamSSE(c, (sse) async {
///   sse.onAbort(() => print('client disconnected'));
///   var i = 0;
///   while (!sse.isAborted) {
///     await sse.writeSSE(SseEvent(event: 'tick', data: '${i++}'));
///     await sse.sleep(Duration(seconds: 1));
///   }
/// }));
/// ```
Future<Response> streamSSE(
  Context c,
  Future<void> Function(DartoSSEWriter writer) callback, {
  Future<void> Function(Object error, DartoSSEWriter writer)? onError,
}) async {
  final httpRes = c.res.raw;
  httpRes.statusCode = 200;
  httpRes.headers.contentType = ContentType('text', 'event-stream');
  httpRes.headers.set('Cache-Control', 'no-cache');
  httpRes.headers.set('Connection', 'keep-alive');
  httpRes.headers.set('X-Accel-Buffering', 'no');

  final writer = DartoSSEWriter._(httpRes);
  unawaited(httpRes.done.then((_) {}, onError: (_) {
    writer._aborted = true;
    writer._onAbortCallback?.call();
  }));

  try {
    await callback(writer);
  } catch (e) {
    if (onError != null) await onError(e, writer);
  } finally {
    try {
      await httpRes.close();
    } catch (_) {}
  }

  return const Response.sent();
}
