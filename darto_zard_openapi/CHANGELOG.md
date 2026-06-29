## 1.0.0

- Initial release. Hono-style `zod-openapi` for Darto:
  - `OpenAPIDarto(darto)` — a composable plugin that wraps your own `Darto`,
    with `openapi(route, middlewares, handler)` and `doc(path, info:, servers:)`.
    Plain routes/middleware and `listen` stay on the `Darto` you pass in.
  - `createRoute({method, path, request, responses})` — a reusable route
    contract, decoupled from the handler.
  - `Req(json:, params:, query:, headers:)` / `Res(status, description, body:)`
    accept zard schemas bridged with `.openapiSchema([name])`.
  - `.openapi({example, description})` extension on zard `Schema<T>` — attaches
    field metadata; `example` is **type-checked** against the schema's type
    (`z.int()` → `int`, `z.string()` → `String`), and stays correct through
    `z.coerce.*`/`transform`.
  - `.openapiSchema([name])` extension on zard `Schema` — names a reusable
    component (`#/components/schemas/<name>`, referenced via `$ref`) or inlines it.
  - `scalarUI(url:)` — serves the Scalar API reference UI.
  - Validation is performed by the zard schemas (via Darto's `validator`
    middleware): full zard power (email/refine/coerce/custom messages), with the
    same schema feeding the generated OpenAPI 3.1 document.
