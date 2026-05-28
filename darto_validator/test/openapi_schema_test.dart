import 'package:darto_validator/darto_validator.dart';
import 'package:test/test.dart';

void main() {
  group('zardToOpenApiSchema', () {
    test('object: types, required, optional, nullable, array, enum', () {
      final schema = z.map({
        'name': z.string(),
        'age': z.int().optional(),
        'nick': z.string().nullable(),
        'tags': z.string().list(),
        'role': z.$enum(['admin', 'user']),
      });

      final m = schema.toOpenApiSchema();

      expect(m['type'], equals('object'));

      final required = (m['required'] as List).cast<String>();
      expect(required, containsAll(['name', 'nick', 'tags', 'role']));
      expect(required, isNot(contains('age'))); // optional → not required

      final props = m['properties'] as Map<String, dynamic>;
      expect(props['name']['type'], equals('string'));
      expect(props['age']['type'], equals('integer'));
      expect(props['nick']['type'], equals(['string', 'null'])); // nullable
      expect(props['tags']['type'], equals('array'));
      expect(props['tags']['items']['type'], equals('string'));
      expect(props['role']['enum'], equals(['admin', 'user']));
    });

    test('default values are emitted', () {
      final schema = z.map({'lang': z.string().$default('en')});
      final props = schema.toOpenApiSchema()['properties'] as Map;
      expect(props['lang']['default'], equals('en'));
    });

    test('nested objects and numbers/booleans', () {
      final schema = z.map({
        'price': z.double(),
        'active': z.bool(),
        'meta': z.map({'views': z.int()}),
      });
      final props = schema.toOpenApiSchema()['properties'] as Map;
      expect(props['price']['type'], equals('number'));
      expect(props['active']['type'], equals('boolean'));
      expect(props['meta']['type'], equals('object'));
      expect(props['meta']['properties']['views']['type'], equals('integer'));
    });
  });
}
