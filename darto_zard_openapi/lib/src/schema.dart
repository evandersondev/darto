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
///
/// Generic over the schema's output type [T] so [openapi]'s `example` is
/// type-checked against it (`z.int()` → `int`, `z.string()` → `String`), and
/// stays correct through `z.coerce.*` and `transform` (whose output type
/// propagates: `TransformedSchema<T, R> extends Schema<R>`).
extension ZardOpenApi<T> on Schema<T> {
  /// Attaches OpenAPI field metadata — the analog of `@hono/zod-openapi`'s
  /// `.openapi({example, description})`. [example] is typed [T], so it must
  /// match the schema's type. Returns the schema for further use (call it
  /// **after** constraints, e.g. `z.int().min(0).openapi(example: 28)`).
  Schema<T> openapi({T? example, String? description}) {
    if (description != null) describe(description);
    if (example != null) this.example(example);
    return this;
  }

  /// Wraps this schema as an [ApiSchema] for use in [Req]/[Res]. Pass a [name]
  /// to register it as a reusable component (`#/components/schemas/<name>`,
  /// referenced with `$ref`); omit it to inline the schema. Call it **last**
  /// (e.g. `z.map({...}).openapiSchema('User')`).
  ApiSchema openapiSchema([String? name]) => ApiSchema(this, name);
}
