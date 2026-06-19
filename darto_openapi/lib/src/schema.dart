/// A schema builder that doubles as a **validator** and an **OpenAPI 3.1
/// Schema Object** generator.
///
/// Constraints are stored as data (not closures), so the same definition both
/// validates a request body and is emitted into the OpenAPI document.
///
/// Fields are **required by default**. Mark a field optional with
/// `required: false`, or override the whole set with the object-level
/// `required:` list (which, when provided, wins over the per-field flags).
///
/// ```dart
/// final user = Schema.object({
///   'name': Schema.string(minLength: 1),
///   'age':  Schema.integer(minimum: 0, required: false), // optional
///   'tags': Schema.array(Schema.string(), required: false),
/// });
///
/// user.validate({'name': 'Ada'});            // → [] (valid; age/tags optional)
/// user.toOpenApi();                           // → OpenAPI Schema Object map
/// ```
class Schema {
  /// The backing OpenAPI Schema Object.
  final Map<String, dynamic> node;

  /// Whether this schema is required when used as a property of an enclosing
  /// [Schema.object]. Ignored in any other position (e.g. array items).
  final bool required;

  const Schema._(this.node, {this.required = true});

  /// Wraps a raw OpenAPI Schema Object — an escape hatch for advanced cases.
  factory Schema.raw(Map<String, dynamic> node, {bool required = true}) =>
      Schema._(Map.of(node), required: required);

  factory Schema.string({
    int? minLength,
    int? maxLength,
    String? format,
    List<String>? enumValues,
    String? pattern,
    String? description,
    Object? example,
    bool nullable = false,
    bool required = true,
  }) =>
      Schema._(
        {
          'type': nullable ? ['string', 'null'] : 'string',
          if (minLength != null) 'minLength': minLength,
          if (maxLength != null) 'maxLength': maxLength,
          if (format != null) 'format': format,
          if (enumValues != null) 'enum': enumValues,
          if (pattern != null) 'pattern': pattern,
          if (description != null) 'description': description,
          if (example != null) 'example': example,
        },
        required: required,
      );

  factory Schema.integer({
    int? minimum,
    int? maximum,
    String? description,
    Object? example,
    bool nullable = false,
    bool required = true,
  }) =>
      Schema._(
        {
          'type': nullable ? ['integer', 'null'] : 'integer',
          if (minimum != null) 'minimum': minimum,
          if (maximum != null) 'maximum': maximum,
          if (description != null) 'description': description,
          if (example != null) 'example': example,
        },
        required: required,
      );

  factory Schema.number({
    num? minimum,
    num? maximum,
    String? description,
    Object? example,
    bool nullable = false,
    bool required = true,
  }) =>
      Schema._(
        {
          'type': nullable ? ['number', 'null'] : 'number',
          if (minimum != null) 'minimum': minimum,
          if (maximum != null) 'maximum': maximum,
          if (description != null) 'description': description,
          if (example != null) 'example': example,
        },
        required: required,
      );

  factory Schema.boolean({
    String? description,
    bool nullable = false,
    bool required = true,
  }) =>
      Schema._(
        {
          'type': nullable ? ['boolean', 'null'] : 'boolean',
          if (description != null) 'description': description,
        },
        required: required,
      );

  factory Schema.array(
    Schema items, {
    int? minItems,
    int? maxItems,
    String? description,
    bool required = true,
  }) =>
      Schema._(
        {
          'type': 'array',
          'items': items.node,
          if (minItems != null) 'minItems': minItems,
          if (maxItems != null) 'maxItems': maxItems,
          if (description != null) 'description': description,
        },
        required: required,
      );

  /// Builds an object schema.
  ///
  /// By default every property is required; mark individual ones optional with
  /// `required: false` on the field. Passing the object-level [required] list
  /// overrides the per-field flags entirely (kept for backward compatibility
  /// and dynamic property maps). The whole object can itself be marked optional
  /// for an enclosing object via [required].
  factory Schema.object(
    Map<String, Schema> properties, {
    List<String>? required,
    bool additionalProperties = true,
    String? description,
    bool isRequired = true,
  }) {
    final req = required ??
        [
          for (final e in properties.entries)
            if (e.value.required) e.key,
        ];
    return Schema._(
      {
        'type': 'object',
        'properties': {
          for (final e in properties.entries) e.key: e.value.node,
        },
        if (req.isNotEmpty) 'required': req,
        if (!additionalProperties) 'additionalProperties': false,
        if (description != null) 'description': description,
      },
      required: isRequired,
    );
  }

  /// The OpenAPI Schema Object map for this schema.
  Map<String, dynamic> toOpenApi() => node;

  /// Validates [value] against this schema, returning a list of human-readable
  /// errors (empty when valid).
  List<String> validate(Object? value, [String path = 'body']) {
    final errors = <String>[];
    _validate(node, value, path, errors);
    return errors;
  }

  static void _validate(
    Map<String, dynamic> n,
    Object? value,
    String path,
    List<String> errors,
  ) {
    final rawType = n['type'];
    final types = rawType is List
        ? rawType.cast<String>()
        : (rawType == null ? const <String>[] : [rawType as String]);

    if (value == null) {
      if (types.isEmpty || types.contains('null')) return;
      errors.add('$path: expected ${types.join(' | ')}, got null');
      return;
    }

    bool isOfType(String t) {
      switch (t) {
        case 'object':
          return value is Map;
        case 'array':
          return value is List;
        case 'string':
          return value is String;
        case 'integer':
          return value is int;
        case 'number':
          return value is num;
        case 'boolean':
          return value is bool;
        default:
          return false;
      }
    }

    final nonNull = types.where((t) => t != 'null').toList();
    if (nonNull.isNotEmpty && !nonNull.any(isOfType)) {
      errors.add('$path: expected ${nonNull.join(' | ')}, got ${value.runtimeType}');
      return;
    }

    if (value is String) {
      final min = n['minLength'];
      if (min is int && value.length < min) {
        errors.add('$path: length must be ≥ $min');
      }
      final max = n['maxLength'];
      if (max is int && value.length > max) {
        errors.add('$path: length must be ≤ $max');
      }
      final allowed = n['enum'];
      if (allowed is List && !allowed.contains(value)) {
        errors.add('$path: must be one of ${allowed.join(', ')}');
      }
      final pattern = n['pattern'];
      if (pattern is String && !RegExp(pattern).hasMatch(value)) {
        errors.add('$path: does not match pattern $pattern');
      }
    } else if (value is num) {
      final min = n['minimum'];
      if (min is num && value < min) errors.add('$path: must be ≥ $min');
      final max = n['maximum'];
      if (max is num && value > max) errors.add('$path: must be ≤ $max');
    }

    if (value is List) {
      final items = n['items'];
      if (items is Map<String, dynamic>) {
        for (var i = 0; i < value.length; i++) {
          _validate(items, value[i], '$path[$i]', errors);
        }
      }
      final min = n['minItems'];
      if (min is int && value.length < min) {
        errors.add('$path: must have ≥ $min items');
      }
      final max = n['maxItems'];
      if (max is int && value.length > max) {
        errors.add('$path: must have ≤ $max items');
      }
    }

    if (value is Map) {
      final required = (n['required'] as List?)?.cast<String>() ?? const [];
      for (final key in required) {
        if (!value.containsKey(key) || value[key] == null) {
          errors.add('$path.$key: is required');
        }
      }
      final props = n['properties'];
      if (props is Map<String, dynamic>) {
        props.forEach((key, sub) {
          if (value.containsKey(key) && sub is Map<String, dynamic>) {
            _validate(sub, value[key], '$path.$key', errors);
          }
        });
        if (n['additionalProperties'] == false) {
          for (final key in value.keys) {
            if (!props.containsKey(key)) {
              errors.add('$path.$key: unexpected property');
            }
          }
        }
      }
    }
  }
}
