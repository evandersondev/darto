import 'package:darto_cli/darto_cli.dart';
import 'package:test/test.dart';

void main() {
  group('toPascalCase', () {
    test('snake_case → PascalCase', () {
      expect(toPascalCase('user_profile'), 'UserProfile');
    });
    test('kebab-case → PascalCase', () {
      expect(toPascalCase('user-profile'), 'UserProfile');
    });
    test('camelCase → PascalCase', () {
      expect(toPascalCase('userProfile'), 'UserProfile');
    });
    test('single word', () {
      expect(toPascalCase('user'), 'User');
    });
  });

  group('toCamelCase', () {
    test('snake_case → camelCase', () {
      expect(toCamelCase('user_profile'), 'userProfile');
    });
    test('PascalCase → camelCase', () {
      expect(toCamelCase('UserProfile'), 'userProfile');
    });
    test('single word is lowercased', () {
      expect(toCamelCase('User'), 'user');
    });
  });

  group('toSnakeCase', () {
    test('camelCase → snake_case', () {
      expect(toSnakeCase('userProfile'), 'user_profile');
    });
    test('PascalCase → snake_case', () {
      expect(toSnakeCase('UserProfile'), 'user_profile');
    });
    test('kebab-case → snake_case', () {
      expect(toSnakeCase('user-profile'), 'user_profile');
    });
  });

  group('toKebabCase', () {
    test('camelCase → kebab-case', () {
      expect(toKebabCase('userProfile'), 'user-profile');
    });
    test('snake_case → kebab-case', () {
      expect(toKebabCase('user_profile'), 'user-profile');
    });
  });

  group('round-trips and edge cases', () {
    test('multi-word camelCase splits on every boundary', () {
      expect(toSnakeCase('myUserProfileController'),
          'my_user_profile_controller');
    });

    test('mixed separators collapse', () {
      expect(toPascalCase('user__profile--name'), 'UserProfileName');
    });

    test('empty string is preserved', () {
      expect(toCamelCase(''), '');
      expect(toPascalCase(''), '');
    });
  });
}
