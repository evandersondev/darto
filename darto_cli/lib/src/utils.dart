/// String case-conversion helpers used by generators and templates.

/// `user_profile` → `UserProfile`
String toPascalCase(String input) {
  return _words(input).map(_capitalize).join();
}

/// `user_profile` → `userProfile`
String toCamelCase(String input) {
  final words = _words(input);
  if (words.isEmpty) return input;
  return words.first.toLowerCase() +
      words.skip(1).map(_capitalize).join();
}

/// `userProfile` / `UserProfile` → `user_profile`
String toSnakeCase(String input) {
  return _words(input).map((w) => w.toLowerCase()).join('_');
}

/// `userProfile` / `UserProfile` → `user-profile`
String toKebabCase(String input) {
  return _words(input).map((w) => w.toLowerCase()).join('-');
}

// ── internal ──────────────────────────────────────────────────────────────────

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

/// Splits any casing style into individual words.
List<String> _words(String input) {
  // Split on non-alphanumeric separators (-, _, space) or camelCase boundaries
  final expanded = input
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (m) => '${m[1]}_${m[2]}',
      )
      .replaceAll(RegExp(r'[-\s]+'), '_');
  return expanded
      .split('_')
      .where((w) => w.isNotEmpty)
      .toList();
}
