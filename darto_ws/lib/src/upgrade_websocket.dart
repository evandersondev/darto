import 'dart:io';

import 'package:darto/darto.dart';

import 'darto_websocket.dart';
import 'ws_event.dart';
import 'ws_handler.dart';
import 'ws_hub.dart';

/// Returns a [Handler] that upgrades the HTTP connection to a WebSocket and
/// wires up the lifecycle callbacks defined in [WSHandler].
///
/// The [factory] receives the current [Context] — path params, headers, and
/// any values set by upstream middleware (e.g. JWT payload) are all available
/// before the upgrade happens.  When a [WsHub] is installed
/// (`app.use(hub.middleware())`), the resulting [DartoWebSocket] is wired to
/// it: `ws.id`, `ws.join`, `ws.to(room)` and friends just work.
///
/// ```dart
/// // Simple echo
/// app.get('/ws', upgradeWebSocket((c) => WSHandler(
///   onOpen:    (ws) => ws.send('connected'),
///   onMessage: (event, ws) => ws.send('echo: ${event.text}'),
///   onClose:   (ws) => print('${ws.id} disconnected'),
/// )));
///
/// // Chat room with broadcast
/// final hub = WsHub();
/// app.use(hub.middleware());
/// app.get('/chat/:room', upgradeWebSocket((c) {
///   final room = c.req.param('room')!;
///   return WSHandler(
///     onOpen: (ws) {
///       ws.join(room);
///       ws.to(room).except(ws).send('${ws.id} joined');
///     },
///     onMessage: (ev, ws) =>
///       ws.to(room).sendJson({'from': ws.id, 'text': ev.text}),
///   );
/// }));
/// ```
Handler upgradeWebSocket(WSHandler Function(Context c) factory) {
  return (Context c) async {
    final httpReq = c.req.raw;

    if (!WebSocketTransformer.isUpgradeRequest(httpReq)) {
      return c.badRequest({'error': 'Expected a WebSocket upgrade request'});
    }

    final hub = wsHub(c);
    final socket = await WebSocketTransformer.upgrade(httpReq);
    final ws = DartoWebSocket(socket, hub: hub);
    hub?.register(ws);

    final handler = factory(c);
    handler.onOpen?.call(ws);

    socket.listen(
      (data) => handler.onMessage?.call(WSEvent(data), ws),
      onDone: () {
        try {
          handler.onClose?.call(ws);
        } finally {
          hub?.unregister(ws);
        }
      },
      onError: (Object e) => handler.onError?.call(e, ws),
      cancelOnError: false,
    );

    return const Response.sent();
  };
}
