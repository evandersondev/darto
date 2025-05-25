import 'dart:io';

import 'package:darto/src/request.dart';
import 'package:darto/src/response.dart';

enum HookType { onRequest, preHandler, onResponse, onError, onNotFound }

typedef RequestHook = void Function(Request req);
typedef PreHandlerHook = Future<void> Function(Request req, Response res);
typedef ResponseHook = void Function(Request req, Response res);
typedef ErrorHook = void Function(dynamic error, Request req, Response res);
typedef NotFoundHook = void Function(Request req, Response res);

class Hooks {
  final List<RequestHook> _onRequest = [];
  final List<PreHandlerHook> _preHandler = [];
  final List<ResponseHook> _onResponse = [];
  final List<ErrorHook> _onError = [];
  final List<NotFoundHook> _onNotFound = [];

  // Métodos para registrar os hooks
  void onRequest(RequestHook callback) => _onRequest.add(callback);
  void preHandler(PreHandlerHook callback) => _preHandler.add(callback);
  void onResponse(ResponseHook callback) => _onResponse.add(callback);
  void onError(ErrorHook callback) => _onError.add(callback);
  void onNotFound(NotFoundHook callback) => _onNotFound.add(callback);

  // Métodos de execução dos hooks
  void executeOnRequest(Request req) {
    for (var hook in _onRequest) {
      hook(req);
    }
  }

  Future<void> executePreHandler(Request req, Response res) async {
    for (var hook in _preHandler) {
      await hook(req, res);
    }
  }

  void executeOnResponse(Request req, Response res) {
    for (var hook in _onResponse) {
      hook(req, res);
    }
  }

  void executeOnError(dynamic error, Request req, Response res) {
    for (var hook in _onError) {
      hook(error, req, res);
    }
  }

  void executeOnNotFound(Request req, Response res) {
    if (_onNotFound.isNotEmpty) {
      for (var hook in _onNotFound) {
        hook(req, res);
      }
    } else {
      res.status(HttpStatus.notFound).send({'error': 'Route not found'});
    }
  }
}
