library darto_ws;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef WebSocketMiddleware = FutureOr<bool> Function(HttpRequest request);

class WebSocketServer {
  final _clients = <WebSocket>[];
  final _middlewares = <WebSocketMiddleware>[];
  final _globalHandlers = <String, void Function(WebSocket)>{};
  final _socketEventHandlers =
      <WebSocket, Map<String, void Function(dynamic)>>{};
  StreamSubscription? _socketSubscription;

  // Método para eventos globais (similar ao Node.js)
  void on(String event, void Function(WebSocket socket) handler) {
    _globalHandlers[event] = handler;
  }

  void use(WebSocketMiddleware middleware) {
    _middlewares.add(middleware);
  }

  Future<bool> executeMiddlewares(HttpRequest req) async {
    for (final middleware in _middlewares) {
      final result = await middleware(req);
      if (!result) return false;
    }
    return true;
  }

  void addClient(WebSocket socket) {
    _clients.add(socket);
    _socketEventHandlers[socket] = <String, void Function(dynamic)>{};

    // Configurar o broadcast para este socket
    WebSocketBroadcast.setServer(this, socket);

    // Chamar handler de conexão
    final connectionHandler = _globalHandlers['connection'];
    if (connectionHandler != null) {
      connectionHandler(socket);
    }

    // Configurar listeners para eventos do socket
    _socketSubscription = socket.listen(
      (data) {
        // Chamar handler global de message se existir
        final messageHandler = _globalHandlers['message'];
        if (messageHandler != null) {
          messageHandler(socket);
        }

        // Processar eventos específicos do socket
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map<String, dynamic> && decoded.containsKey('event')) {
            final event = decoded['event'] as String;
            final eventData = decoded['data'];

            final socketHandlers = _socketEventHandlers[socket];
            if (socketHandlers != null && socketHandlers.containsKey(event)) {
              socketHandlers[event]!(eventData);
            }
          }
        } catch (e) {
          // Se não for JSON válido, trata como mensagem simples
          final socketHandlers = _socketEventHandlers[socket];
          if (socketHandlers != null && socketHandlers.containsKey('message')) {
            socketHandlers['message']!(data);
          }
        }
      },
      onDone: () {
        _clients.remove(socket);
        _socketEventHandlers.remove(socket);

        final closeHandler = _globalHandlers['close'];
        if (closeHandler != null) {
          closeHandler(socket);
        }
      },
      onError: (err) {
        final errorHandler = _globalHandlers['error'];
        if (errorHandler != null) {
          errorHandler(socket);
        }
      },
    );

    // Chamar handler de open
    final openHandler = _globalHandlers['open'];
    if (openHandler != null) {
      openHandler(socket);
    }
  }

  void broadcast(dynamic data) {
    for (final socket in _clients) {
      if (socket.readyState == WebSocket.open) {
        socket.add(data);
      }
    }
  }

  void broadcastJson(Map<String, dynamic> data) {
    broadcast(jsonEncode(data));
  }

  void broadcastEmit(String event, dynamic data) {
    final message = jsonEncode({
      'event': event,
      'data': data,
    });
    broadcast(message);
  }

  List<WebSocket> getClients() => List.unmodifiable(_clients);

  Future<void> close() async {

    if (_socketSubscription != null) {
      await _socketSubscription!.cancel();
      _socketSubscription = null;
    }

    for (final socket in _clients) {
      socket.close();
    }
    _clients.clear();
    _socketEventHandlers.clear();
  }

  // Método interno para registrar event handlers específicos do socket
  void _registerSocketEventHandler(
      WebSocket socket, String event, void Function(dynamic) handler) {
    final socketHandlers = _socketEventHandlers[socket];
    if (socketHandlers != null) {
      socketHandlers[event] = handler;
    }
  }
}

extension WebSocketUtils on WebSocket {
  void sendJson(Map<String, dynamic> data) {
    add(jsonEncode(data));
  }

  // Método emit para enviar dados para o socket específico
  void emit(String event, dynamic data) {
    final message = jsonEncode({
      'event': event,
      'data': data,
    });
    add(message);
  }

  // Método on para escutar eventos específicos
  void on(String event, void Function(dynamic data) handler) {
    final server = WebSocketBroadcast._getServerForSocket(this);
    if (server != null) {
      server._registerSocketEventHandler(this, event, handler);
    }
  }

  // Método destroy para fechar a conexão
  void destroy() {
    close();
  }
}

extension WebSocketBroadcastExtension on WebSocket {
  // Extensão para broadcast que precisa de acesso ao servidor
  WebSocketBroadcast get broadcast => WebSocketBroadcast(this);
}

class WebSocketBroadcast {
  final WebSocket _socket;
  static final Map<WebSocket, WebSocketServer> _socketServerMap = {};

  WebSocketBroadcast(this._socket);

  static void setServer(WebSocketServer server, WebSocket socket) {
    _socketServerMap[socket] = server;
  }

  static WebSocketServer? _getServerForSocket(WebSocket socket) {
    return _socketServerMap[socket];
  }

  void emit(String event, dynamic data) {
    final server = _socketServerMap[_socket];
    if (server != null) {
      final message = jsonEncode({
        'event': event,
        'data': data,
      });

      // Broadcast para todos os outros clientes (exceto o atual)
      for (final socket in server.getClients()) {
        if (socket != _socket && socket.readyState == WebSocket.open) {
          socket.add(message);
        }
      }
    }
  }

  void send(dynamic data) {
    final server = _socketServerMap[_socket];
    if (server != null) {
      // Broadcast para todos os outros clientes (exceto o atual)
      for (final socket in server.getClients()) {
        if (socket != _socket && socket.readyState == WebSocket.open) {
          socket.add(data);
        }
      }
    }
  }
}

extension WebSocketSendExtension on WebSocket {
  void send(dynamic data) => add(data);
  int get id => hashCode;
}
