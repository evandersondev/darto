import 'dart:convert';
import 'dart:io';

/// A WebSocket connection returned to event callbacks.
///
/// Wraps [dart:io]'s [WebSocket] with a typed API.
class DartoWebSocket {
  final WebSocket _socket;

  DartoWebSocket(this._socket);

  /// The close code sent by the peer, or `null` while the connection is open.
  int? get closeCode => _socket.closeCode;

  /// Sends a plain-text [message] to the client.
  void send(String message) => _socket.add(message);

  /// Encodes [data] as JSON and sends it to the client.
  void sendJson(Map<String, dynamic> data) => _socket.add(jsonEncode(data));

  /// Sends raw binary [bytes] to the client.
  void sendBytes(List<int> bytes) => _socket.add(bytes);

  /// Closes the connection with an optional [code] and [reason].
  Future<void> close([int? code, String? reason]) =>
      _socket.close(code, reason);
}
