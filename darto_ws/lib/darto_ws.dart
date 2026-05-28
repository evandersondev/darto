/// WebSocket plugin for the [Darto](https://pub.dev/packages/darto) web
/// framework — route-integrated, same port, with rooms / broadcast and an
/// optional Redis pub/sub adapter for multi-instance fanout.
library darto_ws;

export 'src/darto_websocket.dart';
export 'src/redis_ws_adapter.dart' show RedisWsAdapter;
export 'src/upgrade_websocket.dart';
export 'src/ws_event.dart';
export 'src/ws_handler.dart';
export 'src/ws_hub.dart' show WsHub, WsRecipients, WsAdapter, wsHub;
