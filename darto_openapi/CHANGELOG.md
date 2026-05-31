## 1.0.0

- Initial release.
- `OpenApi(app, info:, servers:)` registry — `get`/`post`/`put`/`patch`/`delete`
  register a route on the app and record it for the spec.
- `Schema` builder (`object`/`string`/`integer`/`number`/`boolean`/`array`/`raw`)
  that generates OpenAPI 3.1 Schema Objects **and** validates values.
- Request validation covers `json` (body), `params` (path), `query` and
  `headers`. Path/query/header values are coerced from strings to the declared
  scalar type before validation; query/header are optional when absent. On
  failure responds `400` with `issues` grouped by target; on success populates
  `c.req.valid('<target>')`.
- `SecurityScheme` (`bearer` / `basic` / `apiKey` / `http`) + per-route
  `security: ['<name>']`, emitted under `components.securitySchemes`.
- `Info`, `Server`, `Req`, `Res` types.
- `docs()` middleware serves `/openapi.json` and a Scalar API reference UI.
- `generateDartClient(spec, {className, baseUrl})` — generates an **end-to-end
  typed Dart client** from the OpenAPI document: model classes (with
  `fromJson`/`toJson`) for request/response bodies and typed methods per
  operation. Dependency-free (`dart:io` + `dart:convert`).
