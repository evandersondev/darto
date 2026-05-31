import 'package:zard/zard.dart';

/// Converts a [zard] [Schema] into an **OpenAPI 3.1 Schema Object** (a plain
/// `Map`), so a schema written once for `zValidator` can also document an API.
///
/// Captures structure: object shape + `required`, arrays (item type), enums
/// (allowed values), nullability, defaults and unions. Fine-grained constraints
/// (`min`/`max`/`format`/`pattern`) are stored as closures inside zard and are
/// **not** introspectable, so they are omitted.
///
/// Pair it with `darto_openapi`'s `Schema.raw(...)`:
///
/// ```dart
/// final userSchema = z.map({'name': z.string()});
///
/// api.post('/users',
///   request: Req(json: Schema.raw(userSchema.toOpenApiSchema())),
///   handler: (c) => c.created(c.req.valid('json')),
/// );
/// ```
Map<String, dynamic> zardToOpenApiSchema(Schema schema) {
  if (schema is ZOptional) return zardToOpenApiSchema(schema.inner);
  if (schema is ZDefault) {
    return {
      ...zardToOpenApiSchema(schema.inner),
      'default': schema.defaultValue,
    };
  }
  if (schema is ZNullable) {
    return _asNullable(zardToOpenApiSchema(schema.inner));
  }
  if (schema is ZUnion) {
    return {
      'oneOf': [for (final s in schema.schemas) zardToOpenApiSchema(s)],
    };
  }
  if (schema is ZMap) {
    final required = <String>[];
    final properties = <String, dynamic>{};
    schema.schemas.forEach((key, sub) {
      properties[key] = zardToOpenApiSchema(sub);
      if (!sub.isOptionalLike) required.add(key);
    });
    return {
      'type': 'object',
      'properties': properties,
      if (required.isNotEmpty) 'required': required,
    };
  }
  if (schema is ZList) {
    return {'type': 'array', 'items': zardToOpenApiSchema(schema.element)};
  }
  if (schema is ZEnum) return {'type': 'string', 'enum': schema.values};
  if (schema is ZString) return {'type': 'string'};
  if (schema is ZInt) return {'type': 'integer'};
  if (schema is ZDouble || schema is ZNum) return {'type': 'number'};
  if (schema is ZBool) return {'type': 'boolean'};
  if (schema is ZDate) return {'type': 'string', 'format': 'date-time'};
  return <String, dynamic>{}; // unknown → permissive (any)
}

/// Adds `'null'` to an OpenAPI Schema Object's type (3.1 style).
Map<String, dynamic> _asNullable(Map<String, dynamic> node) {
  final type = node['type'];
  if (type is String) return {...node, 'type': [type, 'null']};
  if (type is List) {
    return type.contains('null') ? node : {...node, 'type': [...type, 'null']};
  }
  return {...node, 'nullable': true}; // no explicit type (e.g. oneOf)
}

/// Convenience: `schema.toOpenApiSchema()`.
extension ZardOpenApiSchema on Schema {
  Map<String, dynamic> toOpenApiSchema() => zardToOpenApiSchema(this);
}
