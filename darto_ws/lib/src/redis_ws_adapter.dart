import 'dart:async';

import 'package:redis/redis.dart';

import 'ws_hub.dart';

/// Channel prefix for room broadcasts on Redis.  The hub-id-tagged JSON
/// payload allows multiple Darto apps to share a Redis instance without
/// stepping on each other (each app filters by [WsHub.id]).
const _roomPrefix = 'darto_ws:room:';

/// Channel for `broadcast()` — every instance subscribes to it.
const _allChannel = 'darto_ws:all';

/// Redis-backed [WsAdapter] — fans broadcasts out across every app instance.
///
/// Each `hub.to(room).send(...)` or `hub.broadcast().send(...)` is published
/// to a Redis Pub/Sub channel.  Other instances of the same app subscribe to
/// the same channel and re-fanout to their local sockets, skipping messages
/// originating from their own hub to avoid double delivery.
///
/// ```dart
/// final hub = WsHub();
/// await hub.attachAdapter(await RedisWsAdapter.connect(host: 'localhost'));
/// app.use(hub.middleware());
/// ```
class RedisWsAdapter implements WsAdapter {
  RedisWsAdapter._(this._pub, this._sub);

  final Command _pub;
  final PubSub _sub;

  RedisConnection? _pubConn;
  RedisConnection? _subConn;

  WsHub? _hub;
  final Set<String> _subscribedRooms = {};
  StreamSubscription<dynamic>? _stream;

  /// Opens two connections to Redis — one for publishing, one for the
  /// blocking SUBSCRIBE loop.
  static Future<RedisWsAdapter> connect({
    String host = 'localhost',
    int port = 6379,
  }) async {
    final pubConn = RedisConnection();
    final pubCmd = await pubConn.connect(host, port);
    final subConn = RedisConnection();
    final subCmd = await subConn.connect(host, port);
    final adapter = RedisWsAdapter._(pubCmd, PubSub(subCmd));
    adapter._pubConn = pubConn;
    adapter._subConn = subConn;
    return adapter;
  }

  @override
  Future<void> start(WsHub hub) async {
    _hub = hub;
    // Always listen to the broadcast-all channel.
    _sub.subscribe([_allChannel]);
    _stream = _sub.getStream().listen(_onIncoming);
  }

  @override
  void onRoomCreated(String room) {
    if (_subscribedRooms.add(room)) {
      _sub.subscribe([_roomPrefix + room]);
    }
  }

  @override
  void onRoomEmpty(String room) {
    if (_subscribedRooms.remove(room)) {
      _sub.unsubscribe([_roomPrefix + room]);
    }
  }

  @override
  Future<void> publishString({
    required String? room,
    required String payload,
  }) async {
    final hub = _hub;
    if (hub == null) return;
    final channel = room == null ? _allChannel : _roomPrefix + room;
    final wire = encodeWireString(hubId: hub.id, payload: payload);
    await _pub.send_object(['PUBLISH', channel, wire]);
  }

  @override
  Future<void> publishBytes({
    required String? room,
    required List<int> payload,
  }) async {
    final hub = _hub;
    if (hub == null) return;
    final channel = room == null ? _allChannel : _roomPrefix + room;
    final wire = encodeWireBytes(hubId: hub.id, payload: payload);
    await _pub.send_object(['PUBLISH', channel, wire]);
  }

  @override
  Future<void> close() async {
    await _stream?.cancel();
    _stream = null;
    await _subConn?.close();
    await _pubConn?.close();
    _hub = null;
  }

  /// The `redis` package emits each pub/sub event as a `List` shaped
  /// `["message", channel, payload]` (and `["subscribe", channel, count]`
  /// for control frames).  We only react to "message" frames.
  void _onIncoming(dynamic event) {
    if (event is! List || event.length < 3) return;
    final kind = event[0] as String?;
    if (kind != 'message') return;
    final channel = event[1] as String;
    final payload = event[2] as String;
    final hub = _hub;
    if (hub == null) return;

    String? room;
    if (channel == _allChannel) {
      room = null;
    } else if (channel.startsWith(_roomPrefix)) {
      room = channel.substring(_roomPrefix.length);
    } else {
      return; // not ours
    }
    decodeWireAndDispatch(hub: hub, room: room, wire: payload);
  }
}
