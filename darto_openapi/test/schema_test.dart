import 'package:darto_openapi/darto_openapi.dart';
import 'package:test/test.dart';

void main() {
  group('Schema.object required derivation', () {
    test('fields are required by default', () {
      final s = Schema.object({
        'name': Schema.string(),
        'price': Schema.integer(),
      });
      expect(s.node['required'], unorderedEquals(['name', 'price']));
      expect(s.validate({'name': 'a', 'price': 1}), isEmpty);
      expect(s.validate({'name': 'a'}), contains('body.price: is required'));
    });

    test('required: false marks a field optional', () {
      final s = Schema.object({
        'name': Schema.string(),
        'price': Schema.integer(required: false),
      });
      expect(s.node['required'], equals(['name']));
      expect(s.validate({'name': 'a'}), isEmpty);
    });

    test('object-level required list overrides per-field flags', () {
      final s = Schema.object({
        'name': Schema.string(),
        'price': Schema.integer(), // would be required by default
      }, required: ['name']); // ...but the explicit list wins
      expect(s.node['required'], equals(['name']));
      expect(s.validate({'name': 'a'}), isEmpty);
    });

    test('all fields optional → no required key emitted', () {
      final s = Schema.object({
        'name': Schema.string(required: false),
        'price': Schema.integer(required: false),
      });
      expect(s.node.containsKey('required'), isFalse);
    });
  });
}
