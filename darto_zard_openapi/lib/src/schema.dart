import 'package:darto_validator/darto_validator.dart' show zardToOpenApiSchema;
import 'package:zard/zard.dart';

/// A zard [Schema] bridged into the OpenAPI layer, optionally as a named
/// component. Created via the [ZardOpenApi.openapi] extension and consumed by
/// [Req]/[Res]. The underlying zard schema still drives validation; the OpenAPI
/// node is derived from it via `zardToOpenApiSchema`.
class ApiSchema {
  /// The underlying zard schema (validates the request).
  final Schema schema;

  /// Optional component name. When set, the schema is emitted under
  /// `#/components/schemas/<name>` and referenced with `$ref`; otherwise it is
  /// inlined.
  final String? name;

  const ApiSchema(this.schema, [this.name]);

  /// The OpenAPI 3.1 Schema Object for [schema] — types, constraints
  /// (`minLength`/`format`/…) and `description`/`example`.
  Map<String, dynamic> toOpenApi() => zardToOpenApiSchema(schema);
}

/// Bridges a zard [Schema] into the OpenAPI layer — the analog of
/// `@hono/zod-openapi`'s `.openapi()`.
extension ZardOpenApi on Schema {
  /// Returns an [ApiSchema] wrapping this schema. Pass a [name] to register it
  /// as a reusable component (`#/components/schemas/<name>`, referenced with
  /// `$ref`); omit it to inline the schema.
  ///
  /// Call it **after** constraints/metadata, e.g.
  /// `z.string().min(1).describe('Name').openapi('Name')`.
  ApiSchema openapi([String? name]) => ApiSchema(this, name);
}
