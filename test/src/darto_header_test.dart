import 'dart:io';

import 'package:darto/src/darto_header.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../__mocks__/http_mock.dart';

void main() {
  late MockHttpHeaders httpHeaders;
  late DartoHeader dartoHeader;

  setUpAll(() {
    httpHeaders = MockHttpHeaders();
    dartoHeader = DartoHeader(httpHeaders);
  });

  group('DartoHeader', () {
    test('Should be authorization return correctly', () {
      when(() => httpHeaders.value(HttpHeaders.authorizationHeader))
          .thenReturn('Bearer anytoken');

      expect(dartoHeader.authorization, equals('Bearer anytoken'));
      verify(() => httpHeaders.value(HttpHeaders.authorizationHeader))
          .called(1);
    });

    test('Should be return specific value when GET is called', () {
      when(() => httpHeaders.value('any-header')).thenReturn('any-value');

      expect(dartoHeader.get('any-header'), equals('any-value'));
      verify(() => httpHeaders.value('any-header')).called(1);
    });

    test('Should be return all heardes with Map type', () {
      final headersMap = {
        'x-api-key': ['any123'],
        'content-type': ['application/json'],
      };

      when(() => httpHeaders.forEach(any())).thenAnswer((invocation) {
        final Function(String, List<String>) callback =
            invocation.positionalArguments[0];
        headersMap.forEach((key, value) {
          callback(key, value);
        });
      });

      final result = dartoHeader.allHeaders;

      expect(result, equals(headersMap));
      verify(() => httpHeaders.forEach(any())).called(1);
    });
  });
}
