import 'dart:io';

import 'package:darto/darto.dart';
import 'package:darto/src/darto_header.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../__mocks__/http_mock.dart';

final headers = DartoHeaderImpl(MockHttpHeaders());

void main() {
  late MockRequest req;
  late MockResponse res;
  late MockNext next;
  late Upload upload;

  setUp(() {
    req = MockRequest();
    res = MockResponse();
    next = MockNext();
    upload = Upload('./test_uploads');

    // Stub padrão do response
    when(() => res.status(any())).thenReturn(res);
    when(() => res.send(any())).thenReturn(null);
  });

  test('retorna 400 se content-type for inválido', () async {
    when(() => req.headers).thenReturn(headers);

    final middleware = upload.single('file');
    await middleware(req, res, next);

    verify(() => res.status(400)).called(1);
    verify(() => res.send(contains('multipart/form-data'))).called(1);
    verifyNever(() => next());
  });

  test('retorna 400 se não houver boundary no content-type', () async {
    when(() => req.headers).thenReturn(headers);

    final middleware = upload.single('file');
    await middleware(req, res, next);

    verify(() => res.status(400)).called(1);
    verify(() => res.send(contains('multipart/form-data'))).called(1);
    verifyNever(() => next());
  });

  test('retorna 500 se ocorrer erro inesperado', () async {
    when(() => req.headers).thenThrow(Exception('Boom!'));

    final middleware = upload.single('file');
    await middleware(req, res, next);

    verify(() => res.status(500)).called(1);
    verify(() => res.send(contains('Error during file upload'))).called(1);
    verifyNever(() => next());
  });

  tearDown(() async {
    // Limpeza dos arquivos criados nos testes
    final dir = Directory('./test_uploads');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });
}
