import 'dart:io';

import 'package:darto/darto.dart';

import 'darto_websocket.dart';
import 'ws_event.dart';
import 'ws_handler.dart';

/// Returns a [Handler] that upgrades the HTTP connection to a WebSocket and
/// wires up the lifecycle callbacks defined in [WSHandler].
///
/// The [factory] receives the current [Context] — path params, headers, and
/// any values set by upstream middleware (e.g. JWT payload) are all available
/// before the upgrade happens.
///
/// ```dart
/// // Simple echo on the same port as the HTTP server
/// app.get('/ws', upgradeWebSocket((c) => WSHandler(
///   onOpen:    (ws) => ws.send('connected'),
///   onMessage: (event, ws) => ws.send('echo: ${event.text}'),
///   onClose:   () => print('disconnected'),
/// )));
///
/// // With route params and upstream middleware
/// app.get('/chat/:room', upgradeWebSocket((c) {
///   final room = c.req.param('room')!;
///   return WSHandler(
///     onOpen:    (ws) => ws.send('Joined $room'),
///     onMessage: (event, ws) => ws.send('[$room] ${event.text}'),
///   );
/// }), [bearerAuth(secret)]);
/// ```
Handler upgradeWebSocket(WSHandler Function(Context c) factory) {
  return (Context c) async {
    final httpReq = c.req.raw;

    if (!WebSocketTransformer.isUpgradeRequest(httpReq)) {
      return c.badRequest({'error': 'Expected a WebSocket upgrade request'});
    }

    final socket = await WebSocketTransformer.upgrade(httpReq);
    final ws = DartoWebSocket(socket);
    final handler = factory(c);

    handler.onOpen?.call(ws);

    socket.listen(
      (data) => handler.onMessage?.call(WSEvent(data), ws),
      onDone: () => handler.onClose?.call(),
      onError: (Object e) => handler.onError?.call(e),
      cancelOnError: false,
    );

    return const Response.sent();
  };
}
