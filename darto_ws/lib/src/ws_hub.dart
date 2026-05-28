import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:darto/darto.dart';

import 'darto_websocket.dart';

/// State-bag key the [WsHub.middleware] writes to so factories can read the
/// hub via [wsHub].
const _wsHubKey = '__darto_ws_hub';

/// Connection / room registry — one per [Darto] app.
///
/// A hub tracks every open [DartoWebSocket] and the rooms it belongs to, and
/// exposes broadcast helpers usable from anywhere (a WS callback, an HTTP
/// route, a cron, …).
///
/// ```dart
/// final hub = WsHub();
/// final app = Darto()..use(hub.middleware());
///
/// app.get('/chat/:room', upgradeWebSocket((c) {
///   final room = c.req.param('room')!;
///   return WSHandler(
///     onOpen: (ws) {
///       ws.join(room);
///       ws.to(room).except(ws).send('${ws.id} joined');
///     },
///     onMessage: (ev, ws) =>
///       ws.to(room).sendJson({'from': ws.id, 'text': ev.text}),
///     onClose: (ws) {/* leave handled automatically */},
///   );
/// }));
///
/// // Server-initiated broadcast — works from any handler
/// app.post('/announce', [], (c) async {
///   hub.to('lobby').send('shutdown in 5 min');
///   return c.noContent();
/// });
/// ```
class WsHub {
  /// Identifies this hub instance — used to suppress echo when a Redis
  /// [WsAdapter] replays the same broadcast back from another instance.
  final String id = _uuidV4();

  final Map<String, Set<DartoWebSocket>> _rooms = {};
  final Set<DartoWebSocket> _all = {};
  WsAdapter? _adapter;

  /// Every open socket connected to this hub.
  int get connections => _all.length;

  /// Every room with at least one connected socket.
  Iterable<String> get rooms => _rooms.keys;

  /// Number of sockets currently in [room].
  int roomSize(String room) => _rooms[room]?.length ?? 0;

  /// Wires a Redis-backed pub/sub [adapter] so broadcasts fan out to every
  /// instance of the app, not only the one that made the call.
  Future<void> attachAdapter(WsAdapter adapter) async {
    _adapter = adapter;
    await adapter.start(this);
  }

  /// Releases adapter resources and clears every room.  Safe to call multiple
  /// times.
  Future<void> close() async {
    await _adapter?.close();
    _adapter = null;
    _rooms.clear();
    _all.clear();
  }

  /// Darto middleware that exposes this hub to [upgradeWebSocket] factories
  /// (and any other handler) via [wsHub].
  Middleware middleware() {
    return (Context c, Next next) async {
      c.set(_wsHubKey, this);
      await next();
    };
  }

  /// Targets every socket in [room].  Chain [WsRecipients.except] to exclude
  /// the sender, then call [WsRecipients.send] / `sendJson` / `sendBytes`.
  WsRecipients to(String room) =>
      WsRecipients._(this, _rooms[room]?.toList(growable: false) ?? const [], room);

  /// Targets every socket connected to this hub — useful for an app-wide
  /// announcement.
  WsRecipients broadcast() =>
      WsRecipients._(this, _all.toList(growable: false), null);

  // ── Wiring used internally by DartoWebSocket / upgradeWebSocket ──

  void register(DartoWebSocket ws) {
    _all.add(ws);
  }

  void unregister(DartoWebSocket ws) {
    _all.remove(ws);
    for (final r in ws.rooms.toList()) {
      _leave(ws, r);
    }
  }

  void join(DartoWebSocket ws, String room) {
    if (ws.rooms.contains(room)) return;
    (_rooms[room] ??= <DartoWebSocket>{}).add(ws);
    ws.rooms.add(room);
    final isFirst = _rooms[room]!.length == 1;
    if (isFirst) _adapter?.onRoomCreated(room);
  }

  void leave(DartoWebSocket ws, String room) => _leave(ws, room);

  void _leave(DartoWebSocket ws, String room) {
    final members = _rooms[room];
    if (members == null) return;
    members.remove(ws);
    ws.rooms.remove(room);
    if (members.isEmpty) {
      _rooms.remove(room);
      _adapter?.onRoomEmpty(room);
    }
  }

  // ── Dispatch primitives used by WsRecipients ──

  void _sendStringLocal(Iterable<DartoWebSocket> targets, String payload) {
    for (final ws in targets) {
      ws.rawSend(payload);
    }
  }

  void _sendBytesLocal(Iterable<DartoWebSocket> targets, List<int> payload) {
    for (final ws in targets) {
      ws.rawSendBytes(payload);
    }
  }

  /// Called by an attached [WsAdapter] when a remote instance broadcast
  /// reaches us.  Fans out to *local* sockets only — never re-publishes.
  void receiveRemote({
    required String? room,
    required _PayloadKind kind,
    required String data,
  }) {
    final targets = room == null ? _all : (_rooms[room] ?? const <DartoWebSocket>{});
    if (kind == _PayloadKind.string) {
      _sendStringLocal(targets, data);
    } else {
      _sendBytesLocal(targets, base64Decode(data));
    }
  }
}

/// Fluent builder returned by [WsHub.to] / [WsHub.broadcast] (and by
/// [DartoWebSocket.to] / `broadcast`).  Holds the set of target sockets and
/// lets the caller chain `except` before sending.
class WsRecipients {
  WsRecipients._(this._hub, this._targets, this._room);

  final WsHub _hub;
  final List<DartoWebSocket> _targets;

  /// The room name — `null` when the targets come from `broadcast()`.
  final String? _room;

  final Set<DartoWebSocket> _excluded = {};

  /// Excludes [ws] from this fanout.  Most common use: `ws.to(room).except(ws)`.
  WsRecipients except(DartoWebSocket ws) {
    _excluded.add(ws);
    return this;
  }

  Iterable<DartoWebSocket> get _effective =>
      _targets.where((s) => !_excluded.contains(s));

  /// Sends [text] as a text frame to every effective target.
  void send(String text) {
    _hub._sendStringLocal(_effective, text);
    _hub._adapter?.publishString(room: _room, payload: text);
  }

  /// JSON-encodes [data] and sends it as a text frame to every effective
  /// target.  Encoding happens once.
  void sendJson(Object? data) => send(jsonEncode(data));

  /// Sends [bytes] as a binary frame to every effective target.
  void sendBytes(List<int> bytes) {
    _hub._sendBytesLocal(_effective, bytes);
    _hub._adapter?.publishBytes(room: _room, payload: bytes);
  }
}

/// Wire payload kind for [WsAdapter] traffic.
enum _PayloadKind { string, bytes }

/// Pluggable backend that fans broadcasts across multiple app instances.
/// Implemented in `redis_ws_adapter.dart`; the hub doesn't depend on Redis
/// directly — anything that satisfies this contract works.
abstract class WsAdapter {
  /// Hooked by [WsHub.attachAdapter] — receives the owning hub so the adapter
  /// can deliver remote messages back into it.
  Future<void> start(WsHub hub);

  /// Called when [room] becomes non-empty on this instance.  Subscribe the
  /// remote backend if needed.
  void onRoomCreated(String room) {}

  /// Called when the last local socket leaves [room].  Unsubscribe if needed.
  void onRoomEmpty(String room) {}

  /// Publishes a text/JSON broadcast — `room == null` means "all sockets".
  Future<void> publishString({required String? room, required String payload});

  /// Publishes a binary broadcast.
  Future<void> publishBytes({required String? room, required List<int> payload});

  /// Releases any open connections.
  Future<void> close();
}

/// Wire format used by the adapter when crossing the network — encoded as
/// JSON so any Redis-style key/value bus can carry it.
String encodeWireString({required String hubId, required String payload}) =>
    jsonEncode({'id': hubId, 'k': 's', 'd': payload});

String encodeWireBytes({required String hubId, required List<int> payload}) =>
    jsonEncode({'id': hubId, 'k': 'b', 'd': base64Encode(payload)});

/// Decodes a wire message and delivers it to [hub] when the origin id is
/// different from the hub's own (to avoid local echo).
void decodeWireAndDispatch({
  required WsHub hub,
  required String? room,
  required String wire,
}) {
  final m = jsonDecode(wire) as Map<String, dynamic>;
  if (m['id'] == hub.id) return; // own message — already delivered locally
  final kind = m['k'] == 'b' ? _PayloadKind.bytes : _PayloadKind.string;
  hub.receiveRemote(room: room, kind: kind, data: m['d'] as String);
}

/// Reads the [WsHub] off the current request — set by [WsHub.middleware].
WsHub? wsHub(Context c) {
  try {
    return c.get<WsHub?>(_wsHubKey);
  } catch (_) {
    return null;
  }
}

// ── UUID v4 ─────────────────────────────────────────────────────────────────

final _rng = Random.secure();

String _uuidV4() {
  final b = List<int>.generate(16, (_) => _rng.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant 1
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
      '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
}
