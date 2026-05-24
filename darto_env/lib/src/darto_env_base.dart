import 'dart:io';

/// Lightweight environment loader.
///
/// Reads from a `.env` file (defaults to `.env` in the working directory)
/// and merges with [Platform.environment]. `.env` values are stored in memory
/// and accessible via the typed getters. [Platform.environment] always takes
/// precedence over the file (real env wins over file defaults).
///
/// ```dart
/// // At app startup (once):
/// DartoEnv.load();
///
/// // Then anywhere:
/// final secret = DartoEnv.get('JWT_SECRET');
/// final port   = DartoEnv.getInt('PORT', 3000);
/// ```
class DartoEnv {
  static final Map<String, String> _cache = {};

  /// Load variables from [filePath] (default `.env`) into the in-memory cache.
  ///
  /// Skips missing files silently — safe to call in all environments.
  /// Call once at app startup before accessing any variables.
  static void load([String filePath = '.env']) {
    final file = File(filePath);
    if (!file.existsSync()) return;

    for (final raw in file.readAsLinesSync()) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final eq = line.indexOf('=');
      if (eq == -1) continue;

      final key = line.substring(0, eq).trim();
      var value = line.substring(eq + 1).trim();

      // Strip optional surrounding quotes: "value" or 'value'
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }

      if (key.isNotEmpty) _cache[key] = value;
    }
  }

  /// Returns the value for [key].
  ///
  /// Lookup order: [Platform.environment] → .env cache → [defaultValue].
  /// Throws [StateError] if not found and [defaultValue] is null.
  static String get(String key, [String? defaultValue]) {
    final v = Platform.environment[key] ?? _cache[key] ?? defaultValue;
    if (v == null) {
      throw StateError(
          'Environment variable "$key" is not set. '
          'Add it to .env or set it in your environment.');
    }
    return v;
  }

  /// Returns the value as [int]. Falls back to [defaultValue] if missing.
  /// Throws [StateError] if not found and no default, or if value is not an int.
  static int getInt(String key, [int? defaultValue]) {
    final raw = Platform.environment[key] ?? _cache[key];
    if (raw == null) {
      if (defaultValue != null) return defaultValue;
      throw StateError('Environment variable "$key" is not set.');
    }
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      throw FormatException('Environment variable "$key" is not a valid int: "$raw"');
    }
    return parsed;
  }

  /// Returns the value as [double].
  static double getDouble(String key, [double? defaultValue]) {
    final raw = Platform.environment[key] ?? _cache[key];
    if (raw == null) {
      if (defaultValue != null) return defaultValue;
      throw StateError('Environment variable "$key" is not set.');
    }
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      throw FormatException('Environment variable "$key" is not a valid double: "$raw"');
    }
    return parsed;
  }

  /// Returns the value as [bool].
  ///
  /// Truthy: `true`, `1`, `yes`, `on` (case-insensitive).
  static bool getBool(String key, [bool defaultValue = false]) {
    final raw = Platform.environment[key] ?? _cache[key];
    if (raw == null) return defaultValue;
    return const {'true', '1', 'yes', 'on'}.contains(raw.toLowerCase());
  }

  /// Returns null if the key is not set (never throws).
  static String? maybeGet(String key) =>
      Platform.environment[key] ?? _cache[key];

  /// Returns all loaded variables (cache + Platform.environment merged).
  static Map<String, String> all() => {
        ..._cache,
        ...Platform.environment,
      };
}
