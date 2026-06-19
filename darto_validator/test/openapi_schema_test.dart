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

    test('string constraints: min/max/length/format/pattern', () {
      final schema = z.map({
        'name': z.string().min(2).max(50),
        'code': z.string().length(8),
        'email': z.string().email(),
        'site': z.string().url(),
        'id': z.string().uuid(),
        'slug': z.string().regex(RegExp(r'^[a-z-]+$')),
        'born': z.string().date(),
      });
      final p = schema.toOpenApiSchema()['properties'] as Map;
      expect(p['name'], containsPair('minLength', 2));
      expect(p['name'], containsPair('maxLength', 50));
      expect(p['code'], containsPair('minLength', 8));
      expect(p['code'], containsPair('maxLength', 8));
      expect(p['email'], containsPair('format', 'email'));
      expect(p['site'], containsPair('format', 'uri'));
      expect(p['id'], containsPair('format', 'uuid'));
      expect(p['slug'], containsPair('pattern', r'^[a-z-]+$'));
      expect(p['born'], containsPair('format', 'date'));
    });

    test('numeric constraints: min/max/positive/multipleOf', () {
      final schema = z.map({
        'age': z.int().min(0).max(120),
        'qty': z.int().positive(),
        'bal': z.double().nonnegative(),
        'even': z.int().multipleOf(2),
      });
      final p = schema.toOpenApiSchema()['properties'] as Map;
      expect(p['age'], containsPair('minimum', 0));
      expect(p['age'], containsPair('maximum', 120));
      expect(p['qty'], containsPair('exclusiveMinimum', 0));
      expect(p['bal'], containsPair('minimum', 0));
      expect(p['even'], containsPair('multipleOf', 2));
    });

    test('list constraints carry through min/max items', () {
      final schema = z.map({'tags': z.string().list().min(1).max(5)});
      final p = schema.toOpenApiSchema()['properties'] as Map;
      expect(p['tags']['type'], equals('array'));
      expect(p['tags'], containsPair('minItems', 1));
      expect(p['tags'], containsPair('maxItems', 5));
    });

    test('constraints survive nullable/optional wrappers', () {
      final schema = z.map({
        'nick': z.string().min(3).nullable(),
        'note': z.string().max(10).optional(),
      });
      final p = schema.toOpenApiSchema()['properties'] as Map;
      expect(p['nick']['type'], equals(['string', 'null']));
      expect(p['nick'], containsPair('minLength', 3));
      expect(p['note'], containsPair('maxLength', 10));
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
