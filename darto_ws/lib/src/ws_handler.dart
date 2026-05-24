import 'darto_websocket.dart';
import 'ws_event.dart';

/// Defines the lifecycle callbacks for a WebSocket connection.
///
/// All callbacks are optional — only implement what you need.
///
/// ```dart
/// app.get('/ws', upgradeWebSocket((c) => WSHandler(
///   onOpen:    (ws) => ws.send('connected'),
///   onMessage: (event, ws) => ws.send('echo: ${event.text}'),
///   onClose:   () => print('client left'),
///   onError:   (err) => print('error: $err'),
/// )));
/// ```
class WSHandler {
  /// Called once after the WebSocket handshake completes.
  final void Function(DartoWebSocket ws)? onOpen;

  /// Called for every message frame received from the client.
  final void Function(WSEvent event, DartoWebSocket ws)? onMessage;

  /// Called when the connection is closed by either side.
  final void Function()? onClose;

  /// Called when a protocol-level error occurs on the socket.
  final void Function(Object error)? onError;

  const WSHandler({
    this.onOpen,
    this.onMessage,
    this.onClose,
    this.onError,
  });
}
