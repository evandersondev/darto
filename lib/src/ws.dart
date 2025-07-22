library darto_ws;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef WebSocketMiddleware = FutureOr<bool> Function(HttpRequest request);

class WebSocketChannelHandler {
  void Function(WebSocket socket)? _onConnect;
  void Function(WebSocket socket, dynamic message)? _onMessage;
  void Function(WebSocket socket)? _onDisconnect;
  void Function(WebSocket socket, Object error)? _onError;

  WebSocketChannelHandler onConnect(void Function(WebSocket socket) handler) {
    _onConnect = handler;
    return this;
  }

  WebSocketChannelHandler onMessage(
      void Function(WebSocket socket, dynamic message) handler) {
    _onMessage = handler;
    return this;
  }

  WebSocketChannelHandler onDisconnect(
      void Function(WebSocket socket) handler) {
    _onDisconnect = handler;
    return this;
  }

  WebSocketChannelHandler onError(
      void Function(WebSocket socket, Object error) handler) {
    _onError = handler;
    return this;
  }

  void handle(WebSocket socket) {
    _onConnect?.call(socket);
    socket.listen(
      (data) => _onMessage?.call(socket, data),
      onDone: () => _onDisconnect?.call(socket),
      onError: (err) => _onError?.call(socket, err),
    );
  }
}

class WebSocketServer {
  final _clients = <String, List<WebSocket>>{};
  final _handlers = <String, WebSocketChannelHandler>{};
  final _middlewares = <String, List<WebSocketMiddleware>>{};

  WebSocketChannelHandler on(String path) {
    final handler = WebSocketChannelHandler();
    _handlers[path] = handler;
    _clients[path] = [];
    return handler;
  }

  void use(String path, WebSocketMiddleware middleware) {
    _middlewares.putIfAbsent(path, () => []).add(middleware);
  }

  WebSocketChannelHandler? match(String path) => _handlers[path];

  Future<bool> executeMiddlewares(String path, HttpRequest req) async {
    final middlewares = _middlewares[path] ?? [];
    for (final middleware in middlewares) {
      final result = await middleware(req);
      if (!result) return false;
    }
    return true;
  }

  void addClient(String path, WebSocket socket) {
    _clients[path]?.add(socket);
    socket.done.then((_) => _clients[path]?.remove(socket));
  }

  void broadcast(String path, dynamic data) {
    for (final socket in _clients[path] ?? []) {
      if (socket.readyState == WebSocket.open) {
        socket.add(data);
      }
    }
  }

  void sendJson(String path, Map<String, dynamic> data) {
    broadcast(path, jsonEncode(data));
  }

  List<WebSocket> getClients(String path) => _clients[path] ?? [];
}

extension WebSocketUtils on WebSocket {
  void sendJson(Map<String, dynamic> data) {
    add(jsonEncode(data));
  }
}

extension WebSocketSendExtension on WebSocket {
  void send(dynamic data) => add(data);
}
