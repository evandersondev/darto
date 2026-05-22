## 0.0.1

- Initial release — replaces `zard_darto_middleware` with a cleaner API
- `validate(schema)` — validates body (default), query, or params
- `validateBody(schema)` / `validateQuery(schema)` / `validateParams(schema)` — shorthands
- Validated data stored in `req.context['validated']` (configurable key)
- Re-exports `Schema` from Zard so you only need one import
