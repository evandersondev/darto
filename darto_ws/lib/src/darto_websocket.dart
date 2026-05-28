import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'ws_hub.dart';

/// A WebSocket connection returned to event callbacks.
///
/// Wraps [dart:io]'s [WebSocket] with a typed API.  When the socket comes
/// from a [WsHub]-aware [upgradeWebSocket], it also exposes [id], [rooms],
/// [join], [leave], [to] and [broadcast] for room-based fanout.
class DartoWebSocket {
  final WebSocket _socket;
  final WsHub? _hub;

  /// Unique per-connection id (UUID v4) — handy as a `from` field on
  /// outgoing messages.  Generated lazily so unit tests that don't pass a
  /// hub still get a value.
  late final String id = _uuidV4();

  /// Rooms this socket is currently a member of.  Mutated by [join] / [leave]
  /// and cleared on close.  Exposed as a mutable [Set] so the hub can drop
  /// the socket out of every room when the connection ends.
  final Set<String> rooms = <String>{};

  DartoWebSocket(this._socket, {WsHub? hub}) : _hub = hub;

  /// The close code sent by the peer, or `null` while the connection is open.
  int? get closeCode => _socket.closeCode;

  // ── Direct send (no fanout) ────────────────────────────────────────────────

  /// Sends a plain-text [message] to *this* client.
  void send(String message) => _socket.add(message);

  /// Encodes [data] as JSON and sends it to *this* client.
  void sendJson(Map<String, dynamic> data) => _socket.add(jsonEncode(data));

  /// Sends raw binary [bytes] to *this* client.
  void sendBytes(List<int> bytes) => _socket.add(bytes);

  /// Closes the connection with an optional [code] and [reason].
  Future<void> close([int? code, String? reason]) =>
      _socket.close(code, reason);

  // ── Room / fanout helpers (require a hub) ──────────────────────────────────

  /// Adds this socket to [room].  Throws if no [WsHub] was attached at
  /// upgrade time.
  void join(String room) {
    _requireHub('join').join(this, room);
  }

  /// Removes this socket from [room].  No-op if not a member.
  void leave(String room) {
    _requireHub('leave').leave(this, room);
  }

  /// Sends to every socket in [room] — chain [WsRecipients.except] to exclude
  /// yourself before [WsRecipients.send] / `sendJson` / `sendBytes`.
  WsRecipients to(String room) => _requireHub('to').to(room);

  /// Sends to every socket the hub knows about — typically used with `.except(ws)`.
  WsRecipients broadcast() => _requireHub('broadcast').broadcast();

  /// Internal: bypasses encoding and writes a text frame directly.  Used by
  /// [WsHub] when fanning out a pre-encoded payload to many sockets.
  void rawSend(String text) => _socket.add(text);

  /// Internal: writes a binary frame directly.
  void rawSendBytes(List<int> bytes) => _socket.add(bytes);

  WsHub _requireHub(String method) {
    final h = _hub;
    if (h == null) {
      throw StateError(
        'ws.$method() requires a WsHub — install one with '
        'app.use(hub.middleware()) before upgradeWebSocket().',
      );
    }
    return h;
  }
}

// ── UUID v4 (duplicated here so the type stands alone) ──────────────────────

final _rng = Random.secure();

String _uuidV4() {
  final b = List<int>.generate(16, (_) => _rng.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
      '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
}
