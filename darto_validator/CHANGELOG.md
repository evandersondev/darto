## 1.2.0

- `zardToOpenApiSchema()` now emits **fine-grained constraints**, not just
  structure: `minLength`/`maxLength`, `pattern`, `format` (`email`, `uri`,
  `uuid`, `date`, `time`, `date-time`, `ipv4`, `ipv6`, `hostname`), `minimum`/
  `maximum`, `exclusiveMinimum`/`exclusiveMaximum`, `multipleOf`, and
  `minItems`/`maxItems`. Constraints survive `nullable()`/`optional()` wrappers.
  A single zard schema now validates **and** documents an API with full fidelity.
- Require `zard: ^1.2.0` (reads its new introspectable `Schema.checks` metadata).

## 1.1.1

- Require `zard: ^1.1.3`.

## 1.1.0

- Require `darto: ^1.2.0`.
- Add `zardToOpenApiSchema()` and the `Schema.toOpenApiSchema()` extension —
  convert a zard schema into an OpenAPI 3.1 Schema Object map (object shape +
  `required`, arrays, enums, nullability, defaults, unions). Pairs with
  `darto_openapi`'s `Schema.raw(...)`.
- Require `zard: ^1.1.2` (uses its introspection getters/exports).

## 1.0.1

- Require `darto: ^1.1.0`.
- docs: add Support section to README.

## 0.0.1

- Initial release — replaces `zard_darto_middleware` with a cleaner API
- `validate(schema)` — validates body (default), query, or params
- `validateBody(schema)` / `validateQuery(schema)` / `validateParams(schema)` — shorthands
- Validated data stored in `req.context['validated']` (configurable key)
- Re-exports `Schema` from Zard so you only need one import
