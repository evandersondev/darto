import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef DartoSocketChannel = WebSocketChannel;

/// Classe DartoWebsocket para gerenciar conexões WebSocket em tempo real.
///
///
/// Esta classe fornece suporte para:
/// - Conexões recebidas em servidor (através do método listen).
/// - Conexões como cliente (através do método estático connectClient) que utiliza
///   WebSocketChannel.connect conforme a documentação.
class DartoWebsocket {
  // Mapa para armazenar os eventos e seus handlers.
  final Map<String, List<Function>> _handlers = {};

  /// Registra um handler para um evento específico.
  /// Exemplo: on('connection', (WebSocketChannel socket) { ... });
  void on(String event, Function handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
  }

  // Emite o evento para todos os handlers registrados.
  void _emit(String event, dynamic data) {
    if (_handlers.containsKey(event)) {
      for (final handler in _handlers[event]!) {
        handler(data);
      }
    }
  }

  /// Inicia o servidor WebSocket escutando no [address] e [port].
  ///
  /// Quando uma conexão é estabelecida, o evento "connection" é emitido com o canal WebSocket.
  Future<void> listen(String address, int port) async {
    final server = await HttpServer.bind(address, port);
    print("WebSocket server listening on ws://$address:$port");

    await for (HttpRequest request in server) {
      // Verifica se o pedido é para upgrade de conexão WebSocket.
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        WebSocketTransformer.upgrade(request).then((webSocket) {
          // Cria um canal WebSocket a partir da conexão já estabelecida.
          final channel = IOWebSocketChannel(webSocket);
          _emit('connection', channel);
        });
      } else {
        // Retorna Bad Request para conexões não-WebSocket.
        request.response
          ..statusCode = HttpStatus.badRequest
          ..write('WebSocket connections only.')
          ..close();
      }
    }
  }

  /// Método estático para conectar a um WebSocket como cliente.
  ///
  /// Exemplo de uso:
  ///
  /// ```dart
  /// final channel = await DartoWebsocket.connectClient('ws://example.com');
  /// channel.stream.listen((message) {
  ///   channel.sink.add('Echo: $message');
  ///   channel.sink.close(WebSocketStatus.goingAway);
  /// });
  /// ```
  static Future<WebSocketChannel> connectClient(String url) async {
    final uri = Uri.parse(url);
    final channel = WebSocketChannel.connect(uri);
    await channel.ready; // Aguarda a conexão estar pronta.
    return channel;
  }
}
