import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:darto/src/logger.dart';

class DartoStream {
  final HttpResponse _response;
  final bool _showLogger;
  StreamController<List<int>>? _controller;
  Completer<void>? _abortCompleter;
  bool _isClosed = false;

  DartoStream(this._response, this._showLogger) {
    _controller = StreamController<List<int>>(
      onCancel: () {
        _abortCompleter?.complete();
        _close();
      },
    );
    _controller!.stream.listen(
      (data) => _response.add(data),
      onError: (error) => _response.addError(error),
      onDone: () => _close(),
    );
    _abortCompleter = Completer<void>();
  }

  void pipe(Stream<List<int>> stream) {
    if (_isClosed) throw StateError('Stream is already closed');
    stream.listen(
      (data) => _controller?.add(data),
      onError: (error) => _controller?.addError(error),
      onDone: () => _controller?.close(),
      cancelOnError: true,
    );
    if (_showLogger) {
      log.info('Stream piped to DartoStream');
    }
  }

  void write(String data) {
    if (_isClosed) throw StateError('Stream is already closed');
    _controller?.add(utf8.encode(data));
    if (_showLogger) {
      log.info('Wrote data to stream: $data');
    }
  }

  void writeln([String data = '']) {
    if (_isClosed) throw StateError('Stream is already closed');
    _controller?.add(utf8.encode('$data\n'));
    if (_showLogger) {
      log.info('Wrote line to stream: $data');
    }
  }

  Future<void> onAbort(FutureOr<void> Function() callback) {
    if (_isClosed) throw StateError('Stream is already closed');
    return _abortCompleter!.future.then((_) => callback());
  }

  void _close() {
    if (!_isClosed) {
      _controller?.close();
      _response.close();
      _isClosed = true;
      if (_showLogger) {
        log.info('DartoStream closed');
      }
    }
  }
}

extension DartoStreamExtension on DartoStream {
  Logger get log => Logger();
}
